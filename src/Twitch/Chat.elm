module Twitch.Chat exposing (Chat, Msg(..), init, update, view, subscriptions)

{-| This module exposes the core Twitch Chat functionality.

@docs init

@docs Msg, Chat, update, view, subscriptions
-}

import Dom.Scroll as Scroll
import Html exposing (..)
import Html.Events
import Html.Keyed
import Http
import Json.Decode as JD
import Task exposing (Task)
import Twitch.Chat.Badges exposing (Badges)
import Twitch.Chat.Channel
import Twitch.Chat.Chatters exposing (Chatter)
import Twitch.Chat.Css as Css exposing (class, id)
import Twitch.Chat.Header exposing (Header)
import Twitch.Chat.MessageLine as MessageLine exposing (takeMessageId)
import Twitch.Chat.Properties exposing (Properties)
import Twitch.Chat.SendText as SendText exposing (UserMessage)
import Twitch.Chat.Types exposing (Message(SystemMessage))
import WebSocket


{-| The messages our `Chat` responds to.

* `NoOp`: This is the "empty" state change.
the chat messages.
* `ChatTaskResponse`: Respond to the HTTP requests that are needed to setup chat. Right now,
only `Badges` are loaded from the Twitch API.
* `ServerError`: Respond to HTTP errors when processing `ChatTaskResponse`.
* `ChildMessageLineMsg`: This is an intermediary type constructor to route `MessageLine.Msg` to its own module
* `ChildSendTextMsg`: This is an intermediary type constructor to route `SendText.Msg` to its own module
* `ChatScrolled`: means the user has scrolled the chat div up or down
-}
type Msg
    = NoOp
    | ChatTaskResponse (Result Http.Error ChatTaskType)
    | ChildMessageLineMsg MessageLine.Msg
    | ChildSendTextMsg SendText.Msg
    | ChatScrolled OnScrollEvent


{-| The model state for Twitch Chat.
-}
type alias Chat =
    { channelName : String
    , username : String
    , oauth : String
    , header : Header
    , mProperties : Maybe Properties
    , mBadges : Maybe Badges
    , userMessage : UserMessage
    , chatMessages : List Message
    , shouldScroll : Bool
    , chatters : List Chatter
    }


{-| Convenience type for chaining multiple chat requests together
-}
type alias ChatTaskType =
    { channel : Twitch.Chat.Channel.Channel
    , badges : Badges
    , chatters : Twitch.Chat.Chatters.Response
    }


{-| Convenience type for keeping track of the scroll state of
chat div.
-}
type alias OnScrollEvent =
    { height : Float
    , top : Float
    , clientHeight : Float
    }


{-| The subscriptions for WebSocket connections to the Twitch WebSocket IRC server.

## Note

Interesting to note here is our usage of two connections. One connection is for
receiving the chat messages. The other connection is for sending our chat messages
from the chat textarea.

The reasoning behind this is Twitch does not "echo" back your own written messages
with the necessary IRC metadata tags. So badges, emotes and bits are up to you to
decorate. A workaround for this is opening two connections. This allows you to receive
your own messages back with all IRC metadata tags.

This approach needed another workaround. The [`elm-lang/websocket`](http://package.elm-lang.org/packages/elm-lang/websocket/1.0.1/)
implementation distinguishes websockets by their URL. So to have a "sender" and
"receiver" websocket running seperately, their URLs must be different. This is
solved by appending an empty query `"?"` behind Twitch's websocket URL so it
reads `"ws://irc-ws.chat.twitch.tv:80?"`.
-}
subscriptions : Chat -> Sub Msg
subscriptions ({ userMessage } as model) =
    Sub.batch
        [ Sub.map ChildMessageLineMsg (MessageLine.subscriptions receiveWsUrl)
        , Sub.map ChildSendTextMsg (SendText.subscriptions userMessage)
        ]


{-| Initialize the login for connecting to Twitch Chat.

It requires:

* a username
* an OAuth token with the scope `chat_scope`
* a channel name __all lowercase__
-}
init : String -> String -> String -> ( Chat, Cmd Msg )
init username oauth channelName =
    let
        ( userMessage, userMessageCmd ) =
            SendText.init sendWsUrl channelName

        header =
            Twitch.Chat.Header.init channelName

        model =
            { channelName = channelName
            , username = username
            , oauth = oauth
            , header = header
            , mProperties = Nothing
            , mBadges = Nothing
            , userMessage = userMessage
            , shouldScroll = False
            , chatters = []
            , chatMessages = [ SystemMessage "Connecting to chat room..." ]
            }
    in
        model
            ! [ initTasks channelName
                    |> Task.attempt ChatTaskResponse
              , Cmd.map ChildSendTextMsg userMessageCmd
              ]


receiveWsUrl : String
receiveWsUrl =
    "ws://irc-ws.chat.twitch.tv:80"


sendWsUrl : String
sendWsUrl =
    "ws://irc-ws.chat.twitch.tv:80?"


initTasks : String -> Task Http.Error ChatTaskType
initTasks channelName =
    let
        channelTask =
            Twitch.Chat.Channel.getChannel channelName

        badgesTask =
            Task.map (.id >> toString) channelTask
                |> Task.andThen
                    (\aResult ->
                        (Twitch.Chat.Badges.getGlobalBadges
                            |> Task.andThen
                                (\bResult ->
                                    Twitch.Chat.Badges.getSubscriberBadges aResult bResult
                                )
                        )
                    )

        chattersTask =
            Twitch.Chat.Chatters.getChatters channelName
    in
        Task.map3 ChatTaskType
            channelTask
            badgesTask
            chattersTask


{-| Respond to events and model state changes.

-}
update : Msg -> Chat -> ( Chat, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model
                ! []

        ChildMessageLineMsg childMsg ->
            let
                ( message, messageCmd ) =
                    MessageLine.update childMsg receiveWsUrl

                scrollCmd =
                    if model.shouldScroll then
                        Cmd.none
                    else
                        scrollChat
            in
                { model
                    | chatMessages =
                        (model.chatMessages ++ [ message ])
                            |> dropMessagesIfNeeded
                }
                    ! [ Cmd.map ChildMessageLineMsg messageCmd
                      , scrollCmd
                      ]

        ChildSendTextMsg childMsg ->
            let
                ( userMessage, userMessageCmd ) =
                    SendText.update childMsg model.userMessage
            in
                { model | userMessage = userMessage }
                    ! [ Cmd.map ChildSendTextMsg userMessageCmd ]

        ChatTaskResponse (Ok { badges, chatters }) ->
            let
                joinCommands ip =
                    Cmd.batch
                        [ WebSocket.send ip <| "JOIN #" ++ model.channelName
                        , WebSocket.send ip "CAP REQ :twitch.tv/tags"
                        , WebSocket.send ip "CAP REQ :twitch.tv/commands"
                        , WebSocket.send ip <| "NICK " ++ model.username
                        , WebSocket.send ip <| "PASS " ++ model.oauth
                        ]

                loginCmds =
                    [ joinCommands sendWsUrl
                    , joinCommands receiveWsUrl
                    ]

                sendTextModel =
                    model.userMessage
            in
                { model
                    | mBadges = Just badges
                    , chatters = chatters.chatters
                    , userMessage = { sendTextModel | chatters = chatters.chatters }
                    , chatMessages =
                        List.tail model.chatMessages
                            |> Maybe.withDefault []
                            |> (::) (SystemMessage "Connected to chat room.")
                }
                    ! loginCmds

        ChatTaskResponse (Err err) ->
            let
                newMessages =
                    model.chatMessages ++ [ SystemMessage <| toString err ]
            in
                { model | chatMessages = newMessages }
                    ! []

        ChatScrolled event ->
            { model
                | shouldScroll = event.top < (event.height * 0.99 - event.clientHeight)
            }
                ! []


{-| Render the our model state `Chat` in `Html`.
-}
view : Chat -> Html Msg
view model =
    div
        [ class [ Css.Container ]
        ]
        [ Twitch.Chat.Header.view model.header
        , div
            [ class [ Css.ChatRoom ]
            ]
            [ Html.Keyed.node "div"
                [ id Css.ChatDiv
                , class [ Css.ChatMessages ]
                , onScroll ChatScrolled
                ]
                (List.map
                    (MessageLine.view receiveWsUrl model.mBadges)
                    model.chatMessages
                )
            , Html.map ChildSendTextMsg (SendText.view model.userMessage)
            ]
        ]


dropMessagesIfNeeded : List a -> List a
dropMessagesIfNeeded list =
    list
        |> List.length
        >> flip (-) 100
        >> flip List.drop list


onScroll : (OnScrollEvent -> msg) -> Attribute msg
onScroll tagger =
    JD.map tagger onScrollJsonParser
        |> Html.Events.on "scroll"


onScrollJsonParser : JD.Decoder OnScrollEvent
onScrollJsonParser =
    JD.map3 OnScrollEvent
        (JD.at [ "target", "scrollHeight" ] JD.float)
        (JD.at [ "target", "scrollTop" ] JD.float)
        (JD.at [ "target", "clientHeight" ] JD.float)


scrollChat : Cmd Msg
scrollChat =
    Scroll.toBottom (toString Css.ChatDiv)
        |> Task.attempt (always NoOp)

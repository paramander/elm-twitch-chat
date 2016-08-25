module Twitch.Chat exposing (Chat, Msg(..), init, update, view, subscriptions)

{-| This module exposes the core Twitch Chat functionality.

@docs init

@docs Msg, Chat, update, view, subscriptions
-}

import Html exposing (..)
import Html.App
import Http
import Task exposing (Task)
import Twitch.Chat.Badges exposing (Badges)
import Twitch.Chat.Channel
import Twitch.Chat.Css as Css exposing (class, id)
import Twitch.Chat.Header exposing (Header)
import Twitch.Chat.MessageLine as MessageLine
import Twitch.Chat.MessageLine.View as MessageLineView
import Twitch.Chat.Properties exposing (Properties)
import Twitch.Chat.SendText as SendText exposing (UserMessage)
import Twitch.Ports exposing (scrollChat)
import WebSocket


{-| The messages our `Chat` responds to.

* `NoOp`: This is the "empty" state change.
* `UserMessage`: The chat textarea state changes
* `SubmitMessage`: Sending the message in the chat textarea and emptying it
* `RawSendMessage`: Receives IRC lines from the "sender" websocket. A sender websocket has
to receive lines, because it needs to respond to PINGs from IRC.
* `RawReceiveMessage`: Receives IRC lines from the "receiver" websocket and tries to parse
the chat messages.
* `ChatTaskResponse`: Respond to the HTTP requests that are needed to setup chat. Right now,
only `Badges` are loaded from the Twitch API.
* `ServerError`: Respond to HTTP errors when processing `ChatTaskResponse`.
-}
type Msg
    = NoOp
    | ChatTaskResponse ChatTaskType
    | ServerError Http.Error
    | ChildMessageLineMsg MessageLine.Msg
    | ChildSendTextMsg SendText.Msg


{-| The model state for Twitch Chat.
-}
type alias Chat =
    { channelName : String
    , username : String
    , oauth : String
    , header : Header
    , mProperties : Maybe Properties
    , receiveWsUrl : String
    , sendWsUrl : String
    , mBadges : Maybe Badges
    , userMessage : UserMessage
    , messages : List (Html Msg)
    }


{-| Convenience type for chaining multiple chat requests together
-}
type alias ChatTaskType =
    { channel : Twitch.Chat.Channel.Channel
    , badges : Badges
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
subscriptions ({ receiveWsUrl, userMessage } as model) =
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
            SendText.init "ws://irc-ws.chat.twitch.tv:80?" channelName

        header =
            Twitch.Chat.Header.init channelName

        model =
            { channelName = channelName
            , username = username
            , oauth = oauth
            , header = header
            , mProperties = Nothing
            , receiveWsUrl = "ws://irc-ws.chat.twitch.tv:80"
            , sendWsUrl = "ws://irc-ws.chat.twitch.tv:80?"
            , mBadges = Nothing
            , messages = [ MessageLineView.connectingMessage ]
            , userMessage = userMessage
            }
    in
        model
            ! [ initTasks channelName
                    |> Task.perform ServerError ChatTaskResponse
              , Cmd.map ChildSendTextMsg userMessageCmd
              ]


initTasks : String -> Task Http.Error ChatTaskType
initTasks channelName =
    let
        channelTask =
            Twitch.Chat.Channel.getChannel channelName

        badgesTask =
            Task.map (.id >> toString) channelTask
                `Task.andThen` \aResult ->
                                (Twitch.Chat.Badges.getGlobalBadges
                                    `Task.andThen` \bResult ->
                                                    Twitch.Chat.Badges.getSubscriberBadges aResult bResult
                                )
    in
        Task.map2 ChatTaskType
            channelTask
            badgesTask


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
                ( messageHtml, messageCmd ) =
                    MessageLine.render childMsg model.receiveWsUrl model.mBadges
            in
                { model
                    | messages =
                        Html.App.map ChildMessageLineMsg messageHtml
                            |> (\mappedMessageHtml ->
                                    model.messages ++ [ mappedMessageHtml ]
                               )
                            |> dropMessagesIfNeeded
                }
                    ! [ Cmd.map ChildMessageLineMsg messageCmd
                      , scrollChat ()
                      ]

        ChildSendTextMsg childMsg ->
            let
                ( userMessage, userMessageCmd ) =
                    SendText.update childMsg model.userMessage
            in
                { model | userMessage = userMessage }
                    ! [ Cmd.map ChildSendTextMsg userMessageCmd ]

        ChatTaskResponse { badges } ->
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
                    [ joinCommands model.sendWsUrl
                    , joinCommands model.receiveWsUrl
                    ]
            in
                { model
                    | mBadges = Just badges
                    , messages =
                        List.tail model.messages
                            |> Maybe.withDefault []
                            |> (::) MessageLineView.connectedLine
                }
                    ! loginCmds

        ServerError err ->
            let
                newMessages =
                    model.messages ++ [ Html.text <| toString err ]
            in
                { model | messages = newMessages }
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
            [ div
                [ id Css.ChatDiv
                , class [ Css.ChatMessages ]
                ]
                model.messages
            , Html.App.map ChildSendTextMsg (SendText.view model.userMessage)
            ]
        ]


dropMessagesIfNeeded : List a -> List a
dropMessagesIfNeeded list =
    list
        |> List.length
        >> flip (-) 100
        >> flip List.drop list

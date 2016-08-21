module Twitch.Chat exposing (Chat, Msg(..), init, update, view, subscriptions)

{-| This module exposes the core Twitch Chat functionality.

@docs init

@docs Msg, Chat, update, view, subscriptions
-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, on, onWithOptions, onClick, keyCode)
import Http
import Json.Decode as JD
import String
import Task exposing (Task)
import Twitch.Chat.Badges exposing (Badges)
import Twitch.Chat.Channel
import Twitch.Chat.Css as Css
import Twitch.Chat.Header exposing (Header)
import Twitch.Chat.MessageLine as MessageLine
import Twitch.Chat.Parser
import Twitch.Chat.Properties exposing (Properties)
import Twitch.Chat.Types exposing (Message(..))
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
    | UserMessage String
    | SubmitMessage
    | RawSendMessage String
    | RawReceiveMessage String
    | ChatTaskResponse ChatTaskType
    | ServerError Http.Error


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
    , userMessage : String
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
subscriptions ({ receiveWsUrl, sendWsUrl } as model) =
    Sub.batch
        [ WebSocket.listen receiveWsUrl RawReceiveMessage
        , WebSocket.listen sendWsUrl RawSendMessage
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
        model =
            { channelName = channelName
            , username = username
            , oauth = oauth
            , header = Twitch.Chat.Header.init channelName
            , mProperties = Nothing
            , receiveWsUrl = "ws://irc-ws.chat.twitch.tv:80"
            , sendWsUrl = "ws://irc-ws.chat.twitch.tv:80?"
            , mBadges = Nothing
            , userMessage = ""
            , messages = [ MessageLine.connectingMessage ]
            }
    in
        model
            ! [ initTasks channelName
                    |> Task.perform ServerError ChatTaskResponse
              ]


initTasks : String -> Task Http.Error ChatTaskType
initTasks channelName =
    let
        channelTask =
            Twitch.Chat.Channel.getChannel channelName

        badgesTask =
            Task.map (.id >> toString) channelTask
                `Task.andThen` \aResult ->
                    (Twitch.Chat.Badges.getGlobalBadges `Task.andThen` \bResult ->
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

        UserMessage str ->
            { model | userMessage = str }
                ! []

        SubmitMessage ->
            let
                userMessage =
                    String.join ""
                        [ "PRIVMSG #"
                        , model.channelName
                        , " :"
                        , model.userMessage
                        ]
            in
                { model | userMessage = "" }
                    ! [ WebSocket.send model.sendWsUrl userMessage
                      ]

        RawReceiveMessage message ->
            let
                res =
                    Twitch.Chat.Parser.parse message
            in
                case res of
                    Ok message ->
                        case message of
                            PrivateMessage tags user channel content ->
                                { model
                                    | messages =
                                        model.messages
                                            ++ [ MessageLine.viewMessage model.mBadges tags user content ]
                                            |> dropMessagesIfNeeded
                                            |> List.take 100
                                }
                                    ! [ scrollChat () ]

                            Ping content ->
                                model
                                    ! [ WebSocket.send model.receiveWsUrl ("PONG " ++ content) ]

                    Err err ->
                        let
                            _ =
                                Debug.log "RECEIVER PARSE ERR: " err
                        in
                            model ! []

        RawSendMessage message ->
            let
                res =
                    Twitch.Chat.Parser.parse message
            in
                case res of
                    Ok message ->
                        case message of
                            Ping content ->
                                model
                                    ! [ WebSocket.send model.sendWsUrl ("PONG " ++ content) ]

                            _ ->
                                model
                                    ! []

                    Err err ->
                        let
                            _ =
                                Debug.log "SENDER PARSE ERR: " err
                        in
                            model ! []

        ChatTaskResponse { badges } ->
            let
                joinCommands ip =
                    Cmd.batch
                        [ WebSocket.send ip <| "JOIN #" ++ model.channelName
                        , WebSocket.send ip "CAP REQ :twitch.tv/tags :twitch.tv/commands"
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
                            |> (::) MessageLine.connectedLine
                }
                    ! loginCmds

        ServerError err ->
            let
                newMessages =
                    model.messages ++ [ Html.text <| toString err ]
            in
                { model | messages = newMessages }
                    ! []


dropMessagesIfNeeded : List a -> List a
dropMessagesIfNeeded list =
    list
        |> List.length
        >> flip (-) 100
        >> flip List.drop list


{-| Render the our model state `Chat` in `Html`.
-}
view : Chat -> Html Msg
view model =
    div
        [ class "chat-container"
        , style Css.containerStyles
        ]
        [ Twitch.Chat.Header.view model.header
        , div
            [ class "chat-room"
            , style Css.chatRoomStyles
            ]
            [ div
                [ id "ChatDiv"
                , class "chat-messages"
                , style Css.chatMessagesStyles
                ]
                model.messages
            , div
                [ class "chat-interface"
                , style Css.chatInterfaceStyles
                ]
                [ div
                    [ class "textarea-contain"
                    , style Css.textareaContainStyles
                    ]
                    [ viewChatbox model.userMessage
                    ]
                , viewChatButtons
                ]
            ]
        ]


viewChatbox : String -> Html Msg
viewChatbox message =
    textarea
        [ class "chat-input"
        , placeholder "Send a message"
        , style Css.textareaStyles
        , onEnter SubmitMessage
        , preventDefaultOnEnter
        , onInput UserMessage
        , value message
        ]
        []


onEnter : Msg -> Attribute Msg
onEnter msg =
    let
        is13 code =
            if code == 13 then
                msg
            else
                NoOp
    in
        on "keydown"
            (JD.map is13 keyCode)


{-| A workaround to the bug in `elm-lang/virtual-dom` where capturing
the enter button does not work. So two events are used for this: `keydown` and `keypress`.
-}
preventDefaultOnEnter : Attribute Msg
preventDefaultOnEnter =
    onWithOptions "keypress"
        { stopPropagation = False, preventDefault = True }
        <| JD.map (always NoOp)
        <| JD.customDecoder keyCode
            (\code ->
                if code == 13 then
                    Ok code
                else
                    Err "ignore"
            )


viewChatButtons : Html Msg
viewChatButtons =
    div
        [ class "chat-buttons-container"
        , style Css.chatButtonsContainerStyles
        ]
        [ button
            [ class "submit-button"
            , style Css.submitStyles
            , onClick SubmitMessage
            ]
            [ text "Chat" ]
        ]

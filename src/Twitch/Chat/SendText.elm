module Twitch.Chat.SendText exposing (..)

import Html exposing (..)
import Html.Attributes exposing (placeholder, value)
import Html.Events exposing (on, onInput, onClick, onWithOptions, keyCode)
import Json.Decode as JD
import String
import Twitch.Chat.Css as Css exposing (id, class)
import Twitch.Chat.Parser
import Twitch.Chat.Types exposing (Message(..), Channel)
import WebSocket


{-| The messages the chat textarea box responds to.

* `NoOp`: This is the "empty" state change
* `RawMessage`: Receives IRC lines from the websocket and tries to parse ONLY the PING command to keep the connection alive
*
* `UserMessageChanged`: The chat textarea state changes
* `SubmitUserMessage`: Sending the message in the chat textarea and emptying it
-}
type Msg
    = NoOp
    | RawMessage String
    | UserMessageChanged String
    | SubmitUserMessage


type alias UserMessage =
    { content : String
    , sendUrl : String
    , channelName : Channel
    }


subscriptions : UserMessage -> Sub Msg
subscriptions model =
    WebSocket.listen model.sendUrl RawMessage


init : String -> Channel -> ( UserMessage, Cmd Msg )
init sendUrl channelName =
    { content = ""
    , sendUrl = sendUrl
    , channelName = channelName
    }
        ! []


update : Msg -> UserMessage -> ( UserMessage, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model
                ! []

        RawMessage str ->
            case Twitch.Chat.Parser.parse str of
                Ok message ->
                    model
                        ! [ respondToPing model.sendUrl message ]

                Err err ->
                    model
                        ! []

        UserMessageChanged str ->
            { model | content = str }
                ! []

        SubmitUserMessage ->
            let
                message =
                    String.join ""
                        [ "PRIVMSG #"
                        , model.channelName
                        , " :"
                        , model.content
                        ]
            in
                { model | content = "" }
                    ! [ WebSocket.send model.sendUrl message ]


view : UserMessage -> Html Msg
view model =
    div
        [ class [ Css.ChatInterface ]
        ]
        [ div
            [ class [ Css.TextareaContain ]
            ]
            [ viewChatbox model.content
            ]
        , viewChatButtons
        ]


viewChatbox : String -> Html Msg
viewChatbox content =
    textarea
        [ placeholder "Send a message"
        , onEnter SubmitUserMessage
        , preventDefaultOnEnter
        , onInput UserMessageChanged
        , value content
        ]
        []


viewChatButtons : Html Msg
viewChatButtons =
    div
        [ class [ Css.ButtonsContainer ]
        ]
        [ button
            [ class [ Css.Submit ]
            , onClick SubmitUserMessage
            ]
            [ text "Chat" ]
        ]


respondToPing : String -> Message -> Cmd Msg
respondToPing sendUrl message =
    case message of
        Ping content ->
            WebSocket.send sendUrl <| "PONG " ++ content

        _ ->
            Cmd.none


onEnter : Msg -> Attribute Msg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                msg
            else
                NoOp
    in
        on "keydown"
            (JD.map isEnter keyCode)


{-| A workaround to the bug in `elm-lang/virtual-dom` where capturing
the enter button does not work. So two events are used for this: `keydown` and `keypress`.
-}
preventDefaultOnEnter : Attribute Msg
preventDefaultOnEnter =
    keyCode
        |> JD.andThen
            (\code ->
                if code == 13 then
                    JD.succeed code
                else
                    JD.fail "ignore"
            )
        |> JD.map (always NoOp)
        |> onWithOptions "keypress"
            { stopPropagation = False, preventDefault = True }

module Twitch.Chat.MessageLine exposing (..)

import Html exposing (..)
import Twitch.Chat.Badges exposing (Badges, BadgeSets, BadgeProperties)
import Twitch.Chat.MessageLine.View as View
import Twitch.Chat.Parser
import Twitch.Chat.Types exposing (Message(..), User, Channel, Tag(..), Badge(..), Emote)
import WebSocket


{-| The messages that `MessageLine` responds to.

* `RawMessage`: Receives IRC lines from its websocket. It responds to all IRC lines, and not just the PING.
-}
type Msg
    = RawMessage String


subscriptions : String -> Sub Msg
subscriptions receiveUrl =
    WebSocket.listen receiveUrl RawMessage


render : Msg -> String -> Maybe Badges -> ( Html Msg, Cmd Msg )
render msg receiveUrl mBadges =
    case msg of
        RawMessage str ->
            case Twitch.Chat.Parser.parse str of
                Ok message ->
                    spanMessage receiveUrl mBadges message

                Err _ ->
                    text ""
                        ! []


spanMessage : String -> Maybe Badges -> Message -> ( Html Msg, Cmd Msg )
spanMessage receiveUrl mBadges message =
    case message of
        PrivateMessage tags user channel content ->
            View.viewMessage mBadges tags user content
                ! []

        Resubscription tags channel mContent ->
            View.viewResub mBadges tags channel mContent
                ! []

        Subscription channel content ->
            View.viewSub content
                ! []

        ActionMessage tags user channel content ->
            View.viewActionMessage mBadges tags user content
                ! []

        Ping content ->
            text ""
                ! [ WebSocket.send receiveUrl <| "PONG " ++ content ]

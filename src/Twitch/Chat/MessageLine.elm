module Twitch.Chat.MessageLine exposing (..)

import Html exposing (..)
import Twitch.Chat.Badges exposing (BadgeProperties, BadgeSets, Badges)
import Twitch.Chat.MessageLine.View as View
import Twitch.Chat.Parser
import Twitch.Chat.Types exposing (Badge(..), Channel, Emote, Message(..), Tag(..), User)
import WebSocket


{-| The messages that `MessageLine` responds to.

* `RawMessage`: Receives IRC lines from its websocket. It responds to all IRC lines, and not just the PING.
-}
type Msg
    = RawMessage String


subscriptions : String -> Sub Msg
subscriptions receiveUrl =
    WebSocket.listen receiveUrl RawMessage


update : Msg -> String -> ( Message, Cmd Msg )
update msg receiveUrl =
    case msg of
        RawMessage str ->
            let
                parsedMessage =
                    Twitch.Chat.Parser.parse str
                        |> Result.withDefault Ignored
            in
                handleWithPing parsedMessage receiveUrl


handleWithPing : Message -> String -> ( Message, Cmd Msg )
handleWithPing message receiveUrl =
    case message of
        Ping content ->
            Ignored
                ! [ WebSocket.send receiveUrl <| "PONG " ++ content ]

        rest ->
            rest
                ! []


{-| We return a keyed HTML node so Virtual DOM can render
these changes efficiently
-}
view : String -> Maybe Badges -> Message -> ( String, Html a )
view receiveUrl mBadges message =
    case message of
        PrivateMessage tags user channel content ->
            ( takeMessageId tags
            , View.viewMessage mBadges tags user content
            )

        Resubscription tags channel mContent ->
            ( takeUserId tags
            , View.viewResub mBadges tags channel mContent
            )

        Subscription channel content ->
            ( content
            , View.viewSub content
            )

        ActionMessage tags user channel content ->
            ( takeMessageId tags
            , View.viewActionMessage mBadges tags user content
            )

        SystemMessage content ->
            ( content
            , View.viewInfoMessage content
            )

        _ ->
            ( ""
            , text ""
            )


takeMessageId : List Tag -> String
takeMessageId tags =
    case tags of
        [] ->
            Debug.crash "IRCv3 tags are not enabled or message-id tag is missing."

        (Id mId) :: _ ->
            mId

        _ :: rest ->
            takeMessageId rest


takeUserId : List Tag -> String
takeUserId tags =
    case tags of
        [] ->
            Debug.crash "IRCv3 tags are not enabled or user-id tag is missing."

        (UserId mId) :: _ ->
            toString mId

        _ :: rest ->
            takeUserId rest

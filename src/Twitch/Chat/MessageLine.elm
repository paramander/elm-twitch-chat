module Twitch.Chat.MessageLine exposing (..)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import String
import Twitch.Chat.Badges exposing (Badges, BadgeSets)
import Twitch.Chat.Css as Css
import Twitch.Chat.Types exposing (Message(..), User, Channel, Tag(..), Badge(..), Emote)


viewMessage : Maybe Badges -> List Tag -> User -> String -> Html a
viewMessage badgeResponse tags user content =
    div
        [ class "message-line chat-line"
        , style Css.privateMessageStyle
        ]
        [ Maybe.map (badges tags) badgeResponse
            |> Maybe.withDefault (text "")
        , span
            [ class "from"
            , style <| Css.fromStyle tags
            ]
            [ chatFrom tags user ]
        , colon
        , span
            [ class "content"
            , style Css.chatContentStyle
            ]
            <| chatContent tags content
        ]


colon : Html a
colon =
    span
        [ class "colon"
        , style
            <| Css.privateMessageStyle
            ++ [ ( "margin", "0 2px 0 0" )
               , ( "padding", "0" )
               ]
        ]
        [ text ":"
        ]


badges : List Tag -> Badges -> Html a
badges tags badgeResponse =
    case tags of
        [] ->
            text ""

        (Badges badges) :: _ ->
            span [ class "badges" ]
                (viewBadges badgeResponse.badgeSets badges)

        _ :: rest ->
            badges rest badgeResponse


chatFrom : List Tag -> User -> Html a
chatFrom tags user =
    case tags of
        [] ->
            text user

        (DisplayName displayName) :: _ ->
            text displayName

        _ :: rest ->
            chatFrom rest user


chatContent : List Tag -> String -> List (Html a)
chatContent tags content =
    case tags of
        [] ->
            [ text content ]

        (Emotes emotes) :: _ ->
            spanContentWithEmotes 0 emotes content

        _ :: rest ->
            chatContent rest content


spanContentWithEmotes : Int -> List Emote -> String -> List (Html a)
spanContentWithEmotes len emotes content =
    case emotes of
        [] ->
            [ text content ]

        emote :: rest ->
            let
                emoteSrc =
                    String.join "/"
                        [ "//static-cdn.jtvnw.net/emoticons/v1"
                        , toString emote.id
                        , "1.0"
                        ]

                emoteHtml =
                    img
                        [ src emoteSrc
                        , class "emote"
                        , style Css.emoteStyle
                        ]
                        []

                preEmoteContent =
                    String.slice 0 (emote.begin - len) content

                postEmoteContent =
                    String.dropLeft (emote.end + 1 - len) content
            in
                [ text preEmoteContent
                , emoteHtml
                ]
                    ++ spanContentWithEmotes (len + (String.length content) - (String.length postEmoteContent)) rest postEmoteContent


viewBadges : BadgeSets -> List Badge -> List (Html a)
viewBadges badgeSets badges =
    let
        badgeHtml url =
            span
                [ class "badge-wrapper"
                , style Css.badgeStyle
                ]
                [ img
                    [ class "badge"
                    , style Css.badgeImgStyle
                    , src url
                    ]
                    []
                ]

        getBadgeUrl version versions =
            Dict.get version versions
                |> Maybe.map .imageUrl2x
                |> Maybe.withDefault ""
    in
        case badges of
            [] ->
                [ text "" ]

            Subscriber :: rest ->
                badgeSets.subscriber
                    |> Maybe.map (getBadgeUrl "1" >> badgeHtml)
                    |> Maybe.withDefault (text "")
                    |> flip (::) (viewBadges badgeSets rest)

            Turbo :: rest ->
                badgeHtml (getBadgeUrl "1" badgeSets.turbo)
                    :: viewBadges badgeSets rest

            Moderator :: rest ->
                badgeHtml (getBadgeUrl "1" badgeSets.mod)
                    :: viewBadges badgeSets rest

            GlobalMod :: rest ->
                badgeHtml (getBadgeUrl "1" badgeSets.globalMod)
                    :: viewBadges badgeSets rest

            (Bits bits) :: rest ->
                let
                    url =
                        if bits > 99999 then
                            getBadgeUrl "100000" badgeSets.bits
                        else if bits > 9999 then
                            getBadgeUrl "10000" badgeSets.bits
                        else if bits > 4999 then
                            getBadgeUrl "5000" badgeSets.bits
                        else if bits > 999 then
                            getBadgeUrl "1000" badgeSets.bits
                        else if bits > 99 then
                            getBadgeUrl "100" badgeSets.bits
                        else
                            getBadgeUrl "1" badgeSets.bits
                in
                    badgeHtml url
                        :: viewBadges badgeSets rest

            Admin :: rest ->
                badgeHtml (getBadgeUrl "1" badgeSets.admin)
                    :: viewBadges badgeSets rest

            Staff :: rest ->
                badgeHtml (getBadgeUrl "1" badgeSets.staff)
                    :: viewBadges badgeSets rest

            Broadcaster :: rest ->
                badgeHtml (getBadgeUrl "1" badgeSets.broadcaster)
                    :: viewBadges badgeSets rest


connectingMessage : Html a
connectingMessage =
    div
        [ class "message"
        , style
            <| Css.privateMessageStyle
            ++ [ ( "color", "#575260" ) ]
        ]
        [ text "Connecting to chat room..." ]


connectedLine : Html a
connectedLine =
    div
        [ class "message"
        , style
            <| Css.privateMessageStyle
            ++ [ ( "color", "#575260" ) ]
        ]
        [ text "Welcome to the chat room!" ]

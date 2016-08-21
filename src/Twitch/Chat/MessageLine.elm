module Twitch.Chat.MessageLine exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import String
import Twitch.Chat.Badges exposing (Badges)
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
                (viewBadges badgeResponse badges)

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


viewBadges : Badges -> List Badge -> List (Html a)
viewBadges badgeResponse badges =
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
    in
        case badges of
            [] ->
                [ text "" ]

            Subscriber :: rest ->
                badgeResponse.subscriber
                    |> Maybe.map (.image >> badgeHtml)
                    |> Maybe.withDefault (text "")
                    |> flip (::) (viewBadges badgeResponse rest)

            Turbo :: rest ->
                badgeHtml badgeResponse.turbo.image
                    :: viewBadges badgeResponse rest

            Moderator :: rest ->
                badgeHtml badgeResponse.mod.image
                    :: viewBadges badgeResponse rest

            GlobalMod :: rest ->
                badgeHtml badgeResponse.globalMod.image
                    :: viewBadges badgeResponse rest

            (Bits bits) :: rest ->
                let
                    col =
                        if bits > 9999 then
                            "red"
                        else if bits > 4999 then
                            "blue"
                        else if bits > 999 then
                            "green"
                        else if bits > 99 then
                            "purple"
                        else
                            "gray"

                    url =
                        String.join "/"
                            [ "https://static-cdn.jtvnw.net/bits"
                            , "light"
                            , "static"
                            , col
                            , "4"
                            ]
                in
                    badgeHtml url
                        :: viewBadges badgeResponse rest

            Admin :: rest ->
                badgeHtml badgeResponse.admin.image
                    :: viewBadges badgeResponse rest

            Staff :: rest ->
                badgeHtml badgeResponse.staff.image
                    :: viewBadges badgeResponse rest

            Broadcaster :: rest ->
                badgeHtml badgeResponse.broadcaster.image
                    :: viewBadges badgeResponse rest

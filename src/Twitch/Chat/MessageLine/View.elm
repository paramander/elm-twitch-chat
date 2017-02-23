module Twitch.Chat.MessageLine.View exposing (..)

import Dict
import Html exposing (..)
import Html.Attributes exposing (style, src, attribute)
import String
import Twitch.Chat.Badges exposing (Badges, BadgeSets, BadgeProperties)
import Twitch.Chat.Css as Css exposing (id, class)
import Twitch.Chat.Types exposing (Message(..), User, Channel, Tag(..), Badge(..), Emote)


viewMessage : Maybe Badges -> List Tag -> User -> String -> Html a
viewMessage badgeResponse tags user content =
    div
        [ class [ Css.Message, Css.PrivateMessage ]
        ]
        [ Maybe.map (badges tags) badgeResponse
            |> Maybe.withDefault (text "")
        , span
            [ class [ Css.From ]
            , style <| Css.fromStyle tags
            ]
            [ chatFrom tags user ]
        , colon
        , span
            [ class [ Css.Content ]
            ]
          <|
            chatContent tags content
        ]


viewActionMessage : Maybe Badges -> List Tag -> User -> String -> Html a
viewActionMessage badgeResponse tags user content =
    div
        [ class [ Css.Message, Css.PrivateMessage ]
        ]
        [ Maybe.map (badges tags) badgeResponse
            |> Maybe.withDefault (text "")
        , span
            [ class [ Css.From ]
            , style <| Css.fromStyle tags
            ]
            [ chatFrom tags user ]
        , colon
        , span
            [ class [ Css.Content ]
            , style <| Css.fromStyle tags
            ]
          <|
            chatContent tags content
        ]


viewResub : Maybe Badges -> List Tag -> Channel -> Maybe String -> Html a
viewResub badgeResponse tags channel mContent =
    div
        [ class [ Css.Message, Css.ResubMessage ]
        ]
    <|
        systemMessage tags
            :: case mContent of
                Nothing ->
                    [ text "" ]

                Just content ->
                    [ Maybe.map (badges tags) badgeResponse
                        |> Maybe.withDefault (text "")
                    , span
                        [ class [ Css.From ]
                        , style <| Css.fromStyle tags
                        ]
                        [ chatFrom tags "" ]
                    , colon
                    , span
                        [ class [ Css.Content ]
                        ]
                      <|
                        chatContent tags content
                    ]


viewSub : String -> Html a
viewSub content =
    div
        [ class [ Css.Message, Css.ResubMessage ]
        ]
        [ div
            [ class [ Css.SystemMessage ]
            ]
            [ text content ]
        ]


systemMessage : List Tag -> Html a
systemMessage tags =
    case tags of
        [] ->
            text ""

        (System message) :: _ ->
            div
                [ class [ Css.SystemMessage ]
                ]
                [ text message ]

        _ :: rest ->
            systemMessage rest


viewInfoMessage : String -> Html a
viewInfoMessage content =
    div
        [ class [ Css.Notice, Css.Message ] ]
        [ text content ]


colon : Html a
colon =
    span
        [ class [ Css.PrivateMessage, Css.Colon ]
        ]
        [ text ":"
        ]


badges : List Tag -> Badges -> Html a
badges tags badgeResponse =
    case tags of
        [] ->
            text ""

        (Badges badges) :: _ ->
            span [ class [ Css.Badges ] ]
                (viewBadges badgeResponse.badgeSets badges)

        _ :: rest ->
            badges rest badgeResponse


chatFrom : List Tag -> User -> Html a
chatFrom tags user =
    case tags of
        [] ->
            text user

        (DisplayName displayName) :: _ ->
            displayName
                |> Maybe.withDefault user
                |> text

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
                emoteSrc size =
                    String.join "/"
                        [ "//static-cdn.jtvnw.net/emoticons/v1"
                        , toString emote.id
                        , size
                        ]

                preEmoteContent =
                    String.slice 0 (emote.begin - len) content

                emoteContent =
                    String.slice (emote.begin - len) (emote.end + 1 - len) content

                postEmoteContent =
                    String.dropLeft (emote.end + 1 - len) content
            in
                [ text preEmoteContent
                , span
                    [ class [ Css.TooltipWrapper, Css.EmoteWrapper ] ]
                    [ img
                        [ src <| emoteSrc "1.0"
                        , srcset [ emoteSrc "2.0 2x" ]
                        , class [ Css.Emote ]
                        ]
                        []
                    , div
                        [ class [ Css.BalloonTooltip ] ]
                        [ text emoteContent ]
                    ]
                ]
                    ++ spanContentWithEmotes (len + (String.length content) - (String.length postEmoteContent)) rest postEmoteContent


viewBadges : BadgeSets -> List Badge -> List (Html a)
viewBadges badgeSets badges =
    let
        badgeHtml : BadgeProperties -> Html a
        badgeHtml properties =
            span
                [ class [ Css.TooltipWrapper, Css.BalloonWrapper ]
                ]
                [ img
                    [ class [ Css.BadgeImg ]
                    , src properties.imageUrl1x
                    , srcset
                        [ properties.imageUrl2x ++ " 2x"
                        , properties.imageUrl4x ++ " 4x"
                        ]
                    ]
                    []
                , div
                    [ class [ Css.BalloonTooltip ]
                    ]
                    [ text properties.title ]
                ]

        getBadgeVersion version versions =
            Dict.get version versions
                |> Maybe.map badgeHtml
                |> Maybe.withDefault (text "")
    in
        case badges of
            [] ->
                [ text "" ]

            (Subscriber royalty) :: rest ->
                badgeSets.subscriber
                    |> Maybe.map (getBadgeVersion (toString royalty))
                    |> Maybe.withDefault (text "")
                    |> flip (::) (viewBadges badgeSets rest)

            Prime :: rest ->
                getBadgeVersion "1" badgeSets.premium
                    :: viewBadges badgeSets rest

            Turbo :: rest ->
                getBadgeVersion "1" badgeSets.turbo
                    :: viewBadges badgeSets rest

            Moderator :: rest ->
                getBadgeVersion "1" badgeSets.mod
                    :: viewBadges badgeSets rest

            GlobalMod :: rest ->
                getBadgeVersion "1" badgeSets.globalMod
                    :: viewBadges badgeSets rest

            (Bits bits) :: rest ->
                let
                    bitsHtml =
                        if bits > 99999 then
                            getBadgeVersion "100000" badgeSets.bits
                        else if bits > 9999 then
                            getBadgeVersion "10000" badgeSets.bits
                        else if bits > 4999 then
                            getBadgeVersion "5000" badgeSets.bits
                        else if bits > 999 then
                            getBadgeVersion "1000" badgeSets.bits
                        else if bits > 99 then
                            getBadgeVersion "100" badgeSets.bits
                        else
                            getBadgeVersion "1" badgeSets.bits
                in
                    bitsHtml
                        :: viewBadges badgeSets rest

            Admin :: rest ->
                getBadgeVersion "1" badgeSets.admin
                    :: viewBadges badgeSets rest

            Staff :: rest ->
                getBadgeVersion "1" badgeSets.staff
                    :: viewBadges badgeSets rest

            Broadcaster :: rest ->
                getBadgeVersion "1" badgeSets.broadcaster
                    :: viewBadges badgeSets rest


srcset : List String -> Attribute a
srcset =
    String.join ", "
        >> attribute "srcset"

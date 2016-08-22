module Twitch.Chat.Css exposing (..)

import Css exposing (..)
import Css.Elements exposing (..)
import Css.Namespace exposing (namespace)
import Html.CssHelpers
import Twitch.Chat.Types exposing (Tag(..))


{ id, class, classList } =
    Html.CssHelpers.withNamespace twitchChatNamespace


type Ids
    = Twitch
    | ChatDiv


type Classes
    = Header
    | HeaderButton
    | RoomTitle
    | Container
    | ChatRoom
    | ChatMessages
    | ChatInterface
    | TextareaContain
    | ButtonsContainer
    | Submit
    | Message
    | PrivateMessage
    | ResubMessage
    | SystemMessage
    | Badges
    | BadgeImg
    | From
    | Colon
    | Content
    | Notice
    | Emote
    | BalloonWrapper
    | BalloonTooltip


zIndex : Int -> Mixin
zIndex =
    toString >> property "z-index"


twitchChatNamespace : String
twitchChatNamespace =
    "twitchChat_"


css : Stylesheet
css =
    (stylesheet << namespace twitchChatNamespace)
        [ everything
            [ padding zero
            , margin zero
            , boxSizing borderBox
            ]
        , each [ html, body, (#) Twitch ]
            [ width (pct 100)
            , height (pct 100)
            ]
        , (.) Container
            [ backgroundColor (hex "#efeef1")
            , color (rgb 67 63 74)
            , width (pct 100)
            , height (pct 100)
            , position relative
            , minWidth (px 250)
            , fontFamilies
                [ "Helvetica Neue"
                , "Helvetica"
                , "sans-serif"
                ]
            ]
        , (.) ChatRoom
            [ position absolute
            , top (px 50)
            , left zero
            , right zero
            , bottom zero
            , display block
            , zIndex 4
            , property "background-clip" "content-box"
            ]
        , (.) ChatMessages
            [ position absolute
            , width auto
            , height auto
            , top zero
            , left zero
            , right zero
            , bottom (px 111)
            , overflow auto
            ]
        , (.) ChatInterface
            [ height (px 111)
            , width (pct 100)
            , position absolute
            , bottom zero
            , padding3 zero (px 20) (px 20)
            ]
        , (.) TextareaContain
            [ position relative
            , width (pct 100)
            , height (px 50)
            , marginBottom (px 10)
            , descendants
                [ selector "textarea"
                    [ width (pct 100)
                    , height (px 50)
                    , property "resize" "none"
                    , padding (px 7)
                    , fontSize (px 12)
                    , lineHeight (px 20)
                    , color (hex "#706a7c")
                    , verticalAlign top
                    , border3 (px 1) solid (hex "#dad8de")
                    , backgroundColor (hex "#ffffff")
                    , property "outline" "0"
                    ]
                ]
            ]
        , (.) ButtonsContainer
            [ overflow hidden ]
        , (.) Submit
            [ property "float" "right"
            , backgroundColor (hex "#6441a4")
            , border zero
            , position relative
            , color (hex "#ffffff")
            , cursor pointer
            , display inlineBlock
            , fontSize (px 12)
            , lineHeight (px 30)
            , padding2 zero (px 10)
            , margin zero
            ]
        , (.) Header
            [ position relative
            , backgroundColor transparent
            , height (px 50)
            , padding2 (px 10) (Css.rem 0.7)
            , lineHeight (px 30)
            , textAlign center
            , fontSize (px 14)
            , width (pct 100)
            , property "box-shadow" "inset 0 -1px 0 0 #dad8de"
            ]
        , (.) HeaderButton
            [ position absolute
            , top (px 10)
            , left (px 20)
            , padding zero
            , display inlineBlock
            ]
        , (.) RoomTitle
            [ lineHeight (px 20)
            , fontSize (px 12)
            , marginBottom (px -6)
            , paddingTop (px 6)
            ]
        , (.) Message
            [ fontSize (px 12)
            , lineHeight (px 20)
            , padding2 (px 6) (px 20)
            , margin2 (px -3) zero
            , property "word-wrap" "break-word"
            ]
        , (.) PrivateMessage
            []
        , (.) ResubMessage
            [ backgroundColor (hex "#e5e3e8")
            , property "box-shadow" "3px 0 0 #6441a4 inset"
            ]
        , (.) SystemMessage
            [ color (hex "#a49fad")
            ]
        , (.) Badges
            [ property "float" "left"
            , after
                [ property "content" "''"
                , property "display" "table"
                , property "clear" "both"
                , property "visibility" "hidden"
                , fontSize (px 0)
                , height zero
                ]
            ]
        , (.) BadgeImg
            [ height (px 18)
            , minWidth (px 18)
            , display inlineBlock
            , verticalAlign middle
            , property "float" "left"
            , margin4 (px 1) (px 3) (px 1) zero
            ]
        , (.) From
            [ fontWeight (int 700)
            , margin zero
            , padding zero
            ]
        , (.) Colon
            [ margin4 zero (px 2) zero zero
            , padding zero
            ]
        , (.) Content
            [ margin zero
            , padding zero
            ]
        , (.) Notice
            [ color (hex "#575260")
            ]
        , (.) Emote
            [ property "background-center" "center center"
            , property "background-repeat" "no-repeat"
            , display inlineBlock
            , verticalAlign middle
            , margin2 (px -5) zero
            , border zero
            ]
        , (.) BalloonWrapper
            [ position relative
            , property "float" "left"
            , hover
                [ descendants
                    [ (.) BalloonTooltip
                        [ display block
                        , before
                            [ property "content" "''"
                            , position absolute
                            , top (px -6)
                            , left (px -6)
                            , property "width" "calc(100% + 12px)"
                            , property "height" "calc(100% + 12px)"
                            , zIndex -1
                            ]
                        , after
                            [ property "content" "''"
                            , position absolute
                            , left (pct 50)
                            , marginLeft (px -3)
                            , backgroundColor (hex "#0e0c13")
                            , top (px -3)
                            , borderRadius3 (px 1) zero zero
                            , property "border-width" "1px 0 0 1px"
                            , width (px 6)
                            , height (px 6)
                            , transform (rotate (deg 45))
                            , zIndex -1
                            ]
                        ]
                    ]
                ]
            ]
        , (.) BalloonTooltip
            [ left (px 10)
            , transform (translateX (pct -50))
            , backgroundColor (hex "#0e0c13")
            , color (hex "#ffffff")
            , padding2 (px 3) (px 6)
            , property "white-space" "nowrap"
            , property "box-shadow" "none"
            , top (pct 100)
            , marginTop (px 6)
            , borderRadius (px 1)
            , display none
            , fontSize (px 12)
            , lineHeight (px 15)
            , textAlign left
            , zIndex 99999
            , position absolute
            ]
        ]


fromStyle : List Tag -> List ( String, String )
fromStyle tags =
    case tags of
        [] ->
            []

        (Color mColor) :: rest ->
            ( "color", Maybe.withDefault "#8A2BE2" mColor )
                :: fromStyle rest

        _ :: rest ->
            fromStyle rest

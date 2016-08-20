module Twitch.Chat.Css exposing (..)

import Twitch.Chat.Types exposing (Tag(..))


containerStyles : List ( String, String )
containerStyles =
    [ ( "background", "#efeef1" )
    , ( "color", "rgb(67, 63, 74)" )
    , ( "width", "100%" )
    , ( "height", "100%" )
    , ( "position", "relative" )
    , ( "min-width", "250px" )
    , ( "font-family", "Helvetica Neue, Helvetica, sans-serif")
    ]


chatRoomStyles : List ( String, String )
chatRoomStyles =
    [ ( "position", "absolute" )
    , ( "top", "50px" )
    , ( "left", "0" )
    , ( "right", "0" )
    , ( "bottom", "0" )
    , ( "margin", "0" )
    , ( "padding", "0" )
    , ( "display", "block" )
    , ( "z-index", "4" )
    , ( "background-clip", "content-box" )
    ]


chatMessagesStyles : List ( String, String )
chatMessagesStyles =
    [ ( "position", "absolute" )
    , ( "width", "auto" )
    , ( "height", "auto" )
    , ( "top", "0" )
    , ( "bottom", "111px" )
    , ( "left", "0" )
    , ( "right", "0" )
    , ( "margin", "0" )
    , ( "padding", "0" )
    , ( "overflow", "auto" )
    ]


chatInterfaceStyles : List ( String, String )
chatInterfaceStyles =
    [ ( "height", "111px" )
    , ( "width", "100%" )
    , ( "position", "absolute" )
    , ( "padding", "0 20px 20px" )
    , ( "box-sizing", "border-box" )
    , ( "bottom", "0" )
    ]


textareaContainStyles : List ( String, String )
textareaContainStyles =
    [ ( "position", "relative" )
    , ( "width", "100%" )
    , ( "height", "50px" )
    , ( "margin-bottom", "10px" )
    ]


textareaStyles : List ( String, String )
textareaStyles =
    [ ( "width", "100%" )
    , ( "height", "50px" )
    , ( "padding-right", "25px" )
    , ( "margin", "0" )
    , ( "resize", "none" )
    , ( "padding", "7px" )
    , ( "font-size", "12px" )
    , ( "line-height", "20px" )
    , ( "color", "#706a7c" )
    , ( "vertical-align", "top" )
    , ( "border", "1px solid #dad8de" )
    , ( "box-sizing", "border-box" )
    , ( "background", "white" )
    , ( "outline", "0" )
    ]


chatButtonsContainerStyles : List ( String, String )
chatButtonsContainerStyles =
    [ ( "overflow", "hidden" )
    , ( "margin", "0" )
    , ( "padding", "0" )
    ]


submitStyles : List ( String, String )
submitStyles =
    [ ( "float", "right" )
    , ( "background-color", "#6441a4" )
    , ( "border", "0" )
    , ( "position", "relative" )
    , ( "color", "white" )
    , ( "cursor", "pointer" )
    , ( "display", "inline-block" )
    , ( "font-size", "12px" )
    , ( "line-height", "30px" )
    , ( "height", "30px" )
    , ( "padding", "0 10px" )
    , ( "margin", "0" )
    ]


headerStyles : List ( String, String )
headerStyles =
    [ ( "position", "relative" )
    , ( "background", "transparent" )
    , ( "height", "50px" )
    , ( "padding", "10px 0.7rem" )
    , ( "line-height", "30px" )
    , ( "text-align", "center" )
    , ( "font-size", "14px" )
    , ( "width", "100%" )
    , ( "box-shadow", "inset 0 -1px 0 0 #dad8de" )
    , ( "box-sizing", "border-box" )
    ]


headerButtonStyle : List ( String, String )
headerButtonStyle =
    [ ( "position", "absolute" )
    , ( "top", "10px" )
    , ( "left", "20px" )
    , ( "padding", "0" )
    , ( "display", "inline-block" )
    ]


roomTitleStyles : List ( String, String )
roomTitleStyles =
    [ ( "line-height", "20px" )
    , ( "font-size", "12px" )
    , ( "margin", "0" )
    , ( "padding", "0" )
    , ( "margin-bottom", "-6px" )
    , ( "padding-top", "6px" )
    , ( "box-sizing", "border-box" )
    ]


privateMessageStyle : List ( String, String )
privateMessageStyle =
    [ ( "font-size", "12px" )
    , ( "line-height", "20px" )
    , ( "padding", "6px 20px" )
    , ( "margin", "-3px 0" )
    , ( "word-wrap", "break-word" )
    , ( "box-sizing", "border-box" )
    ]


badgeStyle : List ( String, String )
badgeStyle =
    [ ( "float", "left" )
    , ( "margin", "0" )
    , ( "padding", "0" )
    ]


badgeImgStyle : List ( String, String )
badgeImgStyle =
    [ ( "height", "18px" )
    , ( "min-width", "18px" )
    , ( "display", "inline-block" )
    , ( "vertical-align", "middle" )
    , ( "float", "left" )
    , ( "margin", "1px 3px 1px 0" )
    ]


fromStyle : List Tag -> List ( String, String )
fromStyle tags =
    case tags of
        [] ->
            [ ( "font-weight", "700" )
            , ( "margin", "0" )
            , ( "padding", "0" )
            ]

        (Color mColor) :: rest ->
            ( "color", Maybe.withDefault "#8A2BE2" mColor )
                :: fromStyle rest

        _ :: rest ->
            fromStyle rest


chatContentStyle : List ( String, String )
chatContentStyle =
    privateMessageStyle
        ++ [ ( "margin", "0" )
           , ( "padding", "0" )
           ]


emoteStyle : List ( String, String )
emoteStyle =
    [ ( "background-position", "center center" )
    , ( "background-repeat", "no-repeat" )
    , ( "display", "inline-block" )
    , ( "vertical-align", "middle" )
    , ( "margin", "-5px 0" )
    , ( "border", "0" )
    ]

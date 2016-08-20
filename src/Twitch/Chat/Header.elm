module Twitch.Chat.Header exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, style)
import Svg
import Svg.Attributes as SvgAttr
import Twitch.Chat.Css as Css


type alias Header =
    { channelName : String
    }


init : String -> Header
init =
    Header


view : Header -> Html a
view model =
    div
        [ class "chat-header"
        , style Css.headerStyles
        ]
        [ div
            [ class "chat-header__button"
            , style Css.headerButtonStyle
            ]
            [ Svg.svg
                [ SvgAttr.height "16px"
                , SvgAttr.width "16px"
                , SvgAttr.viewBox "0 0 16 16"
                , SvgAttr.fill "#6441a4"
                , SvgAttr.style "vertical-align: middle;"
                ]
                [ Svg.path
                    [ SvgAttr.clipRule "evenodd"
                    , SvgAttr.d "M1,13v-2h14v2H1z M1,5h13v2H1V5z M1,2h10v2H1V2z M12,10H1V8h11V10z"
                    , SvgAttr.fillRule "evenodd"
                    ]
                    []
                ]
            ]
        , p
            [ class "room-title"
            , style Css.roomTitleStyles
            ]
            [ text model.channelName ]
        ]

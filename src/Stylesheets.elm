port module Stylesheets exposing (..)

import Css.File exposing (..)
import Twitch.Chat.Css
import Html exposing (div)
import Html.App exposing (program)


port files : CssFileStructure -> Cmd msg


cssFiles : CssFileStructure
cssFiles =
    toFileStructure [ ( "styles.css", compile Twitch.Chat.Css.css )]


main : Program Never
main =
    program
        { init = ( (), files cssFiles )
        , update = \_ _ -> ( (), Cmd.none )
        , view = \_ -> div [] []
        , subscriptions = \_ -> Sub.none
        }

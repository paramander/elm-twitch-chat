port module Stylesheets exposing (..)

import Css.File exposing (..)
import Twitch.Chat.Css
import Platform exposing (program)


port files : CssFileStructure -> Cmd msg


cssFiles : CssFileStructure
cssFiles =
    toFileStructure [ ( "styles.css", compile [ Twitch.Chat.Css.css ] ) ]


main : Program Never () msg
main =
    program
        { init = ( (), files cssFiles )
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = \_ -> Sub.none
        }

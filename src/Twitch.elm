module Twitch exposing (..)

import Html exposing (program)
import Twitch.Chat exposing (Chat, Msg)


main : Program Never Chat Msg
main =
    program
        { init = Twitch.Chat.init username oauth channel
        , update = Twitch.Chat.update
        , view = Twitch.Chat.view
        , subscriptions = Twitch.Chat.subscriptions
        }


channel : String
channel =
    "lirik"


username : String
username =
    -- uncomment the line below and fill in with your username
    -- "justinfan12345"


{-| Make sure the oauth token includes the prefix "oauth:".

   You can get one at https://twitchapps.com/tmi
-}
oauth : String
oauth =
    -- uncomment the line below and fill in with your oauth token
    -- "oauth:jfj4u417al9gabb2taprpilup8e22w"

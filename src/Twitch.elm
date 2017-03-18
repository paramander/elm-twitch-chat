module Twitch exposing (..)

import Html exposing (programWithFlags)
import Twitch.Chat exposing (Chat, Msg)


type alias Flags =
    { username : String
    , oauth : String
    , channel : String
    }


main : Program Flags Chat Msg
main =
    programWithFlags
        { init = (\({ username, oauth, channel } as flags) -> Twitch.Chat.init username oauth channel)
        , update = Twitch.Chat.update
        , view = Twitch.Chat.view
        , subscriptions = Twitch.Chat.subscriptions
        }

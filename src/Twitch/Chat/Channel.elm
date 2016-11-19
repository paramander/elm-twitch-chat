module Twitch.Chat.Channel exposing (..)

import Http
import Json.Decode as JD exposing (Decoder, field)
import String
import Task exposing (Task)
import Twitch.Request as Request


type alias Channel =
    { id : Int
    , name : String
    , displayName : String
    , game : String
    }


getChannel : String -> Task Http.Error Channel
getChannel channelName =
    let
        url =
            String.join "/"
                [ "https://api.twitch.tv/kraken/channels"
                , channelName
                ]
    in
        Request.attempt channelDecoder url


channelDecoder : Decoder Channel
channelDecoder =
    JD.map4 Channel
        (field "_id" JD.int)
        (field "name" JD.string)
        (field "display_name" JD.string)
        (field "game" JD.string)

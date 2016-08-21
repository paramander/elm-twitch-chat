module Twitch.Chat.Channel exposing (..)

import Http
import Json.Decode as JD exposing (Decoder, (:=))
import String
import Task exposing (Task)


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
        Http.get channelDecoder url


channelDecoder : Decoder Channel
channelDecoder =
    JD.object4 Channel
        ("_id" := JD.int)
        ("name" := JD.string)
        ("display_name" := JD.string)
        ("game" := JD.string)

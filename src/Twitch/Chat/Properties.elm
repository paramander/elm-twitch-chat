module Twitch.Chat.Properties exposing (..)

import Http
import Json.Decode as JD exposing (Decoder, (:=))
import String
import Task exposing (Task)


type Status
    = Loading
    | Loaded
    | Error Http.Error


type alias Properties =
    { subsonly : Bool
    , chatServers : List String
    , webSocketServers : List String
    , status : Status
    }


getProperties : String -> Task Http.Error Properties
getProperties channelName =
    let
        url =
            String.join "/"
                [ "https://api.twitch.tv/api/channels"
                , channelName
                , "chat_properties"
                ]
    in
        Http.get decodeProperties url


decodeProperties : Decoder Properties
decodeProperties =
    JD.object4 Properties
        ("subsonly" := JD.bool)
        ("chat_servers" := JD.list JD.string)
        ("web_socket_servers" := JD.list JD.string)
        (JD.succeed Loaded)

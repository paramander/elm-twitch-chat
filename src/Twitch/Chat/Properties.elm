module Twitch.Chat.Properties exposing (..)

import Http
import Json.Decode as JD exposing (Decoder, field)
import String
import Task exposing (Task)
import Twitch.Request as Request


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
        Request.attempt decodeProperties url


decodeProperties : Decoder Properties
decodeProperties =
    JD.map4 Properties
        (field "subsonly" JD.bool)
        (field "chat_servers" <| JD.list JD.string)
        (field "web_socket_servers" <| JD.list JD.string)
        (JD.succeed Loaded)

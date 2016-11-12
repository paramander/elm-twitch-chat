module Twitch.Chat.Chatters exposing (..)

{-| This module is for querying the TMI to periodically
fetch current users in a channel.
-}

import Http
import Json.Decode as JD exposing (Decoder, (:=))
import String
import Twitch.Request as Request
import Task exposing (Task)


type alias Chatter =
    String


type alias Response =
    { count : Int
    , chatters : List Chatter
    }


getChatters : String -> Task Http.Error Response
getChatters channelName =
    let
        url =
            String.join "/"
                [ "http://tmi.twitch.tv/group/user"
                , channelName
                , "chatters"
                ]
    in
        Request.attempt (JD.at [ "data" ] responseDecoder) url


responseDecoder : Decoder Response
responseDecoder =
    JD.object2 Response
        ("chatter_count" := JD.int)
        <| "chatters"
        := (chattersDecoder "moderators"
                `JD.andThen` (\prev -> JD.map (\staff -> prev ++ staff) (chattersDecoder "staff"))
                `JD.andThen` (\prev -> JD.map (\admins -> prev ++ admins) (chattersDecoder "admins"))
                `JD.andThen` (\prev -> JD.map (\globalMods -> prev ++ globalMods) (chattersDecoder "global_mods"))
                `JD.andThen` (\prev -> JD.map (\viewers -> prev ++ viewers) (chattersDecoder "viewers"))
           )


chattersDecoder : String -> Decoder (List Chatter)
chattersDecoder key =
    (key := JD.list JD.string)

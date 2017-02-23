module Twitch.Chat.Chatters exposing (..)

{-| This module is for querying the TMI to periodically
fetch current users in a channel.
-}

import Dict exposing (Dict)
import Http
import Json.Decode as JD exposing (Decoder, field)
import Task exposing (Task)
import Twitch.Request as Request


type alias Chatter =
    String


type alias Response =
    { count : Int
    , chatters : Dict String (List Chatter)
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
    JD.map2 Response
        (field "chatter_count" JD.int)
        (field "chatters" (JD.dict chattersDecoder))


chattersDecoder : Decoder (List Chatter)
chattersDecoder =
    JD.list JD.string

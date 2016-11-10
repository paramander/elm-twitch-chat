module Twitch.Request exposing (..)

import Http
import Json.Decode exposing (Decoder)
import Jsonp
import Task exposing (Task)


clientId : String
clientId =
    "tgvu4jvazvcibhhxrtelm674k8z8tvj"


attempt : Decoder value -> String -> Task Http.Error value
attempt decoder url =
    Http.url url [ ( "client_id", clientId ) ]
        |> Jsonp.get decoder

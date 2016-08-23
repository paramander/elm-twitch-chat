module Jsonp exposing (jsonp, get)

import Http
import Json.Decode as Json
import Native.Jsonp
import Task exposing (Task)


get : Json.Decoder value -> String -> Task Http.Error value
get decoder url =
    let
        decode s =
            Json.decodeString decoder s
                |> Task.fromResult
                |> Task.mapError Http.UnexpectedPayload
    in
        jsonp url
            |> Task.mapError (always Http.NetworkError)
            |> flip Task.andThen decode


jsonp : String -> Task Never String
jsonp =
    Native.Jsonp.jsonp

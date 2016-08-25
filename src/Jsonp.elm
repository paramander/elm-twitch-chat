module Jsonp exposing (jsonp, get)

import Http
import Json.Decode as Json
import Native.Jsonp
import Random
import Random.Char
import Random.String
import Task exposing (Task)
import Time


get : Json.Decoder value -> String -> Task Http.Error value
get decoder url =
    let
        decode s =
            Json.decodeString decoder s
                |> Task.fromResult
                |> Task.mapError Http.UnexpectedPayload
    in
        randomCallbackName
            |> flip Task.andThen (jsonp url)
            |> Task.mapError (always Http.NetworkError)
            |> flip Task.andThen decode


jsonp : String -> String -> Task x String
jsonp =
    Native.Jsonp.jsonp


randomCallbackName : Task x String
randomCallbackName =
    let
        generator =
            Random.String.string 10 Random.Char.latin
    in
        Time.now
            |> Task.map (round >> Random.initialSeed)
            |> Task.map (Random.step generator >> fst)

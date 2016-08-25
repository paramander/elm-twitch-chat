module Jsonp exposing (jsonp, get)

import Http
import Json.Decode as Json
import Native.Jsonp
import Random
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
            `Task.andThen` jsonp url
            `Task.andThen` decode


jsonp : String -> String -> Task x String
jsonp =
    Native.Jsonp.jsonp


randomCallbackName : Task x String
randomCallbackName =
    let
        generator =
            Random.int 100 Random.maxInt
    in
        Time.now
            |> Task.map (round >> Random.initialSeed)
            |> Task.map (Random.step generator >> fst)
            |> Task.map (toString >> (++) "callback")

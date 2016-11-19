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
    makeUrl url [ ( "client_id", clientId ) ]
        |> Jsonp.get decoder


makeUrl : String -> List ( String, String ) -> String
makeUrl baseUrl args =
    case args of
        [] ->
            baseUrl

        _ ->
            baseUrl ++ "?" ++ String.join "&" (List.map queryPair args)


queryPair : ( String, String ) -> String
queryPair ( key, value ) =
    queryEscape key ++ "=" ++ queryEscape value


queryEscape : String -> String
queryEscape string =
    String.join "+" (String.split "%20" (Http.encodeUri string))

module Twitch.Chat.Badges exposing (..)

import Http
import Json.Decode as JD exposing (Decoder, (:=))
import String
import Task exposing (Task)


type Status
    = Loading
    | Loaded
    | Error Http.Error


type alias Url =
    String


type alias BadgeProperties =
    { image : Url }


type alias Badges =
    { globalMod : BadgeProperties
    , admin : BadgeProperties
    , broadcaster : BadgeProperties
    , mod : BadgeProperties
    , staff : BadgeProperties
    , turbo : BadgeProperties
    , subscriber : Maybe BadgeProperties
    }


getBadges : String -> Task Http.Error Badges
getBadges channelName =
    let
        url =
            String.join "/"
                [ "https://api.twitch.tv/kraken/chat"
                , channelName
                , "badges"
                ]
    in
        Http.get badgesDecoder url


badgesDecoder : Decoder Badges
badgesDecoder =
    JD.object7 Badges
        ("global_mod" := badgePropertiesDecoder)
        ("admin" := badgePropertiesDecoder)
        ("broadcaster" := badgePropertiesDecoder)
        ("mod" := badgePropertiesDecoder)
        ("staff" := badgePropertiesDecoder)
        ("turbo" := badgePropertiesDecoder)
        ("subscriber" := JD.maybe badgePropertiesDecoder)


badgePropertiesDecoder : Decoder BadgeProperties
badgePropertiesDecoder =
    JD.object1 BadgeProperties
        ("image" := JD.string)

module Twitch.Chat.Badges exposing (..)

import Dict exposing (Dict)
import Http
import Json.Decode as JD exposing (Decoder, field)
import Json.Decode.Extra exposing ((|:))
import String
import Task exposing (Task)
import Twitch.Request as Request


type alias Url =
    String


type alias Badges =
    { badgeSets : BadgeSets }


type alias BadgeSets =
    { bits : BadgeVersions
    , globalMod : BadgeVersions
    , admin : BadgeVersions
    , broadcaster : BadgeVersions
    , mod : BadgeVersions
    , staff : BadgeVersions
    , turbo : BadgeVersions
    , premium : BadgeVersions
    , subscriber : Maybe BadgeVersions
    }


type alias BadgeVersions =
    Dict String BadgeProperties


type alias BadgeProperties =
    { imageUrl1x : Url
    , imageUrl2x : Url
    , imageUrl4x : Url
    , description : String
    , title : String
    , clickAction : String
    , clickUrl : String
    }


getGlobalBadges : Task Http.Error Badges
getGlobalBadges =
    getBadges "global" globalBadgeSetsDecoder


getSubscriberBadges : String -> Badges -> Task Http.Error Badges
getSubscriberBadges channelId globalBadges =
    subscriberBadgeSetsDecoder globalBadges.badgeSets
        |> getBadges ("channels/" ++ channelId)


getBadges : String -> Decoder BadgeSets -> Task Http.Error Badges
getBadges channelId decoder =
    let
        url =
            String.join "/"
                [ "https://badges.twitch.tv/v1/badges"
                , channelId
                , "display"
                ]
    in
        Request.attempt (badgesDecoder decoder) url


badgesDecoder : Decoder BadgeSets -> Decoder Badges
badgesDecoder decoder =
    JD.map Badges
        (field "badge_sets" decoder)


globalBadgeSetsDecoder : Decoder BadgeSets
globalBadgeSetsDecoder =
    JD.succeed BadgeSets
        |: (field "bits" badgeVersionsDecoder)
        |: (field "global_mod" badgeVersionsDecoder)
        |: (field "admin" badgeVersionsDecoder)
        |: (field "broadcaster" badgeVersionsDecoder)
        |: (field "moderator" badgeVersionsDecoder)
        |: (field "staff" badgeVersionsDecoder)
        |: (field "turbo" badgeVersionsDecoder)
        |: (field "premium" badgeVersionsDecoder)
        |: (field "subscriber" <| JD.succeed Nothing)


subscriberBadgeSetsDecoder : BadgeSets -> Decoder BadgeSets
subscriberBadgeSetsDecoder badges =
    JD.map (BadgeSets badges.bits badges.globalMod badges.admin badges.broadcaster badges.mod badges.staff badges.turbo badges.premium)
        (field "subscriber" <| JD.maybe badgeVersionsDecoder)


badgeVersionsDecoder : Decoder BadgeVersions
badgeVersionsDecoder =
    JD.at [ "versions" ] <| JD.dict badgePropertiesDecoder


badgePropertiesDecoder : Decoder BadgeProperties
badgePropertiesDecoder =
    JD.map7 BadgeProperties
        (field "image_url_1x" JD.string)
        (field "image_url_2x" JD.string)
        (field "image_url_4x" JD.string)
        (field "description" JD.string)
        (field "title" JD.string)
        (field "click_action" JD.string)
        (field "click_url" JD.string)

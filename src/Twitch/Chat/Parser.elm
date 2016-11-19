module Twitch.Chat.Parser exposing (..)

import Combine exposing (..)
import Combine.Char exposing (..)
import Combine.Num exposing (..)
import String
import Twitch.Chat.Types
    exposing
        ( Message(..)
        , Badge(..)
        , Tag(..)
        , Channel
        , User
        , Command
        , Mode
        , Emote
        )


{-| Intermediary state of a parsed emote.

Emotes can have multiple occurences. But having a `List EmoteOccurence`
during rendering makes it unnecessarily difficult when applying the
emotes to the message content.
-}
type alias ParsedEmote =
    { id : Int
    , indices : List EmoteOccurence
    }


type alias EmoteOccurence =
    { begin : Int
    , end : Int
    }


(<$>) : Parser s a -> (a -> b) -> Parser s b
(<$>) =
    flip Combine.map


($>) : Parser s a -> b -> Parser s b
($>) =
    flip (<$)


bool : Parser s Bool
bool =
    int <$> ((==) 1)


rest : Parser s String
rest =
    manyTill anyChar end
        <$> String.fromList


parse : String -> Result String Message
parse ircMessage =
    case Combine.parse message ircMessage of
        Ok (_, _, m) ->
            Ok m

        Err (_, stream, ms) ->
            String.join ""
                [ toString ms
                , ", "
                , toString stream
                ]
                |> Debug.log "parse error"
                |> Err


message : Parser s Message
message =
    choice
        [ actionMessage
        , privMessage
        , pingMessage
        , resubMessage
        , subMessage
        ]


pingMessage : Parser s Message
pingMessage =
    succeed Ping
        <* string "PING"
        <* space
        <*> (manyTill anyChar end <$> String.fromList)


actionMessage : Parser s Message
actionMessage =
    succeed ActionMessage
        <*> privMsgTags
        <*> commandPrefix
        <* string "PRIVMSG "
        <*> channel
        <* space
        <* char ':'
        <* string "\x01ACTION"
        <* space
        <*> rest


privMessage : Parser s Message
privMessage =
    succeed PrivateMessage
        <*> privMsgTags
        <*> commandPrefix
        <* string "PRIVMSG "
        <*> channel
        <* space
        <* char ':'
        <*> rest


resubMessage : Parser s Message
resubMessage =
    succeed Resubscription
        <*> userStateTags
        <* string ":tmi.twitch.tv"
        <* space
        <* string "USERNOTICE "
        <*> channel
        <*> maybe (space <* char ':' *> rest)



-- ":twitchnotify!twitchnotify@twitchnotify.tmi.twitch.tv PRIVMSG #lirik :LegalizeDragonDildos just subscribed!\r\n"


subMessage : Parser s Message
subMessage =
    succeed Subscription
        <* string ":twitchnotify!twitchnotify@twitchnotify.tmi.twitch.tv"
        <* space
        <* string "PRIVMSG "
        <*> channel
        <* space
        <* char ':'
        <*> rest


nickname : Parser s String
nickname =
    many (regex "[a-zA-Z0-9]" <|> string "_") <$> String.concat


username : Parser s User
username =
    nickname


channel : Parser s Channel
channel =
    char '#'
        *> nickname


commandPrefix : Parser s User
commandPrefix =
    char ':'
        *> nickname
        *> char '!'
        *> username
        <* char '@'
        <* nickname
        <* char '.'
        <* string "tmi.twitch.tv"
        <* space


privMsgTags : Parser s (List Tag)
privMsgTags =
    manyTill privMsgTag (char ' ')


userStateTags : Parser s (List Tag)
userStateTags =
    manyTill userStateTag (char ' ')


privMsgTag : Parser s Tag
privMsgTag =
    badges
        <|> bits
        <|> color
        <|> displayName
        <|> emotes
        <|> id
        <|> mod
        <|> roomId
        <|> subscriber
        <|> sentTimestamp "tmi-sent-ts"
        <|> sentTimestamp "sent-ts"
        <|> turbo
        <|> userId
        <|> userType


userStateTag : Parser s Tag
userStateTag =
    privMsgTag
        <|> msgId
        <|> msgParamMonths
        <|> systemMsg
        <|> login


badges : Parser s Tag
badges =
    string "@badges"
        *> char '='
        *> sepBy (char ',') badge
        <* char ';'
        <$> Badges


badge : Parser s Badge
badge =
    let
        badgeParser b =
            string b *> char '/' *> int
    in
        choice
            [ badgeParser "subscriber" <$> Subscriber
            , badgeParser "turbo" $> Turbo
            , badgeParser "moderator" $> Moderator
            , string "bits" *> char '/' *> int <$> Bits
            , badgeParser "admin" $> Admin
            , badgeParser "staff" $> Staff
            , badgeParser "global_mod" $> GlobalMod
            , badgeParser "premium" $> Prime
            , badgeParser "broadcaster" $> Broadcaster
            ]


bits : Parser s Tag
bits =
    string "bits"
        *> char '='
        *> int
        <* char ';'
        <$> BitsTag


color : Parser s Tag
color =
    string "color"
        *> char '='
        *> maybe (regex "#[a-fA-F0-9]{6}")
        <* char ';'
        <$> Color


displayName : Parser s Tag
displayName =
    string "display-name"
        *> char '='
        *> (manyTill anyChar (char ';') <$> String.fromList)
        <$> DisplayName


emotes : Parser s Tag
emotes =
    string "emotes"
        *> char '='
        *> sepBy (char '/') emote
        <* char ';'
        <$> (transformEmotes >> List.concat >> List.sortBy .begin >> Emotes)


{-| Convert the intermediary `ParsedEmote`s to actual
`Emote`s that will be used for applying the emotes to the
chat message.
-}
transformEmotes : List ParsedEmote -> List (List Emote)
transformEmotes parsedEmotes =
    case parsedEmotes of
        [] ->
            []

        pe :: rest ->
            List.map (\occurence -> Emote pe.id occurence.begin occurence.end) pe.indices
                :: transformEmotes rest


emote : Parser s ParsedEmote
emote =
    succeed ParsedEmote
        <*> int
        <* char ':'
        <*> sepBy (char ',') emoteOccurence


emoteOccurence : Parser s EmoteOccurence
emoteOccurence =
    succeed EmoteOccurence
        <*> int
        <* char '-'
        <*> int


id : Parser s Tag
id =
    string "id"
        *> char '='
        *> manyTill anyChar (char ';')
        <$> (String.fromList >> Id)


mod : Parser s Tag
mod =
    string "mod"
        *> char '='
        *> bool
        <* char ';'
        <$> ModTag


roomId : Parser s Tag
roomId =
    string "room-id"
        *> char '='
        *> int
        <* char ';'
        <$> RoomId


subscriber : Parser s Tag
subscriber =
    string "subscriber"
        *> char '='
        *> bool
        <* char ';'
        <$> SubTag


sentTimestamp : String -> Parser s Tag
sentTimestamp timestampTag =
    string timestampTag
        *> char '='
        *> int
        <* char ';'
        <$> always None


turbo : Parser s Tag
turbo =
    string "turbo"
        *> char '='
        *> bool
        <* char ';'
        <$> TurboTag


userId : Parser s Tag
userId =
    string "user-id"
        *> char '='
        *> int
        <* char ';'
        <$> UserId


userType : Parser s Tag
userType =
    let
        userTypes =
            [ string "mod"
            , string "global_mod"
            , string "admin"
            , string "staff"
            ]
    in
        string "user-type"
            *> char '='
            *> maybe (choice userTypes)
            <$> UserType


systemMsg : Parser s Tag
systemMsg =
    string "system-msg"
        *> char '='
        *> manyTill anyChar (char ';')
        <$> (String.fromList >> String.split "\\s" >> String.join " " >> System)


login : Parser s Tag
login =
    string "login"
        *> char '='
        *> username
        <* char ';'
        <$> always None


msgId : Parser s Tag
msgId =
    string "msg-id"
        *> char '='
        *> string "resub"
        <* char ';'
        <$> always None


msgParamMonths : Parser s Tag
msgParamMonths =
    string "msg-param-months"
        *> char '='
        *> int
        <* char ';'
        <$> always None

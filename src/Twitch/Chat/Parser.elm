module Twitch.Chat.Parser exposing (..)

import Combine exposing (..)
import Combine.Char exposing (..)
import Combine.Infix exposing ((<*>), (<*), (*>), (<$), (<|>))
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


(<$>) : Parser a -> (a -> b) -> Parser b
(<$>) =
    flip Combine.map


($>) : Parser a -> b -> Parser b
($>) =
    flip (<$)


bool : Parser Bool
bool =
    int <$> ((==) 1)


rest : Parser String
rest =
    manyTill anyChar end
        <$> String.fromList


parse : String -> Result (List String) Message
parse =
    Combine.parse message
        >> fst


message : Parser Message
message =
    choice
        [ privMessage
        , pingMessage
        ]


pingMessage : Parser Message
pingMessage =
    succeed Ping
        <* string "PING"
        <* space
        <*> (manyTill anyChar end <$> String.fromList)


privMessage : Parser Message
privMessage =
    succeed PrivateMessage
        <*> tags
        <*> commandPrefix
        <* string "PRIVMSG "
        <*> channel
        <* space
        <* char ':'
        <*> rest


nickname : Parser String
nickname =
    many (regex "[a-zA-Z0-9]" <|> string "_") <$> String.concat


username : Parser User
username =
    nickname


channel : Parser Channel
channel =
    char '#'
        *> nickname


commandPrefix : Parser User
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


tags : Parser (List Tag)
tags =
    manyTill tag (char ' ')


tag : Parser Tag
tag =
    badges
        <|> bits
        <|> color
        <|> displayName
        <|> emotes
        <|> id
        <|> mod
        <|> roomId
        <|> subscriber
        <|> turbo
        <|> userId
        <|> userType


badges : Parser Tag
badges =
    string "@badges"
        *> char '='
        *> sepBy (char ',') badge
        <* char ';'
        <$> Badges


badge : Parser Badge
badge =
    let
        badgeParser b =
            string b *> char '/' *> many1 int
    in
        choice
            [ badgeParser "broadcaster" $> Broadcaster
            , badgeParser "staff" $> Staff
            , badgeParser "admin" $> Admin
            , badgeParser "global_mod" $> GlobalMod
            , badgeParser "moderator" $> Moderator
            , badgeParser "turbo" $> Turbo
            , badgeParser "subscriber" $> Subscriber
            , string "bits" *> char '/' *> int <$> Bits
            ]


bits : Parser Tag
bits =
    string "bits"
        *> char '='
        *> int
        <* char ';'
        <$> BitsTag


color : Parser Tag
color =
    string "color"
        *> char '='
        *> maybe (regex "#[a-fA-F0-9]{6}")
        <* char ';'
        <$> Color


displayName : Parser Tag
displayName =
    string "display-name"
        *> char '='
        *> (manyTill anyChar (char ';') <$> String.fromList)
        <$> DisplayName


emotes : Parser Tag
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


emote : Parser ParsedEmote
emote =
    succeed ParsedEmote
        <*> int
        <* char ':'
        <*> sepBy (char ',') emoteOccurence


emoteOccurence : Parser EmoteOccurence
emoteOccurence =
    succeed EmoteOccurence
        <*> int
        <* char '-'
        <*> int


id : Parser Tag
id =
    string "id"
        *> char '='
        *> manyTill anyChar (char ';')
        <$> (String.fromList >> Id)


mod : Parser Tag
mod =
    string "mod"
        *> char '='
        *> bool
        <* char ';'
        <$> ModTag


roomId : Parser Tag
roomId =
    string "room-id"
        *> char '='
        *> int
        <* char ';'
        <$> RoomId


subscriber : Parser Tag
subscriber =
    string "subscriber"
        *> char '='
        *> bool
        <* char ';'
        <$> SubTag


turbo : Parser Tag
turbo =
    string "turbo"
        *> char '='
        *> bool
        <* char ';'
        <$> TurboTag


userId : Parser Tag
userId =
    string "user-id"
        *> char '='
        *> int
        <* char ';'
        <$> UserId


userType : Parser Tag
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

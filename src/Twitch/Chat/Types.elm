module Twitch.Chat.Types exposing (..)


{-| The `Message`s we process from IRC. Right now, only PRIVMSG and PING are
parsed. JOINs, SERVERMSG and JTV messages are not processed to.
-}
type Message
    = PrivateMessage (List Tag) User Channel String
    | Resubscription (List Tag) Channel (Maybe String)
    | Subscription Channel String
    | Ping String
    -- | ServerMessage (Maybe Channel) Int String
    -- | JtvCommand Command String
    -- | JtvMode User Channel Mode


type Tag
    = Badges (List Badge)
    | BitsTag Int
    | Color (Maybe String)
    | DisplayName String
    | Emotes (List Emote)
    | Id String
    | ModTag Bool
    | RoomId Int
    | SubTag Bool
    | TurboTag Bool
    | UserId Int
    | UserType (Maybe String)
    | System String
    | None


type Badge
    = Broadcaster
    | Staff
    | Admin
    | GlobalMod
    | Moderator
    | Turbo
    | Subscriber Int
    | Bits Int


type alias Channel =
    String


type alias User =
    String


type alias Command =
    String


type alias Mode =
    String


type alias Emote =
    { id : Int
    , begin : Int
    , end : Int
    }

module Twitch.Chat.SendText exposing (..)

import Autocomplete
import Char exposing (KeyCode)
import Html exposing (..)
import Html.Attributes exposing (placeholder, tabindex, value)
import Html.Events exposing (keyCode, on, onClick, onInput, onMouseEnter, onWithOptions)
import Json.Decode as JD
import Json.Decode.Extra as JDE
import Regex exposing (Regex)
import Twitch.Chat.Chatters exposing (Chatter)
import Twitch.Chat.Css as Css exposing (class, id)
import Twitch.Chat.Parser
import Twitch.Chat.Types exposing (Channel, Message(..))
import WebSocket


{-| The messages the chat textarea box responds to.

* `NoOp`: This is the "empty" state change
* `RawMessage`: Receives IRC lines from the websocket and tries to parse ONLY the PING command to keep the connection alive
*
* `UserMessageChanged`: The chat textarea state changes
* `SubmitUserMessage`: Sending the message in the chat textarea and emptying it
-}
type Msg
    = NoOp
    | RawMessage String
    | UserMessageChanged String
    | SubmitUserMessage
    | SetAutocompleteState Autocomplete.Msg
    | SelectPerson Chatter
    | Reset Bool


type alias UserMessage =
    { content : String
    , sendUrl : String
    , channelName : Channel
    , chatters : List Chatter
    , autoState : Autocomplete.State
    , showSuggestions : Bool
    }


subscriptions : UserMessage -> Sub Msg
subscriptions model =
    Sub.batch
        [ WebSocket.listen model.sendUrl RawMessage
        , Sub.map SetAutocompleteState Autocomplete.subscription
        ]


init : String -> Channel -> ( UserMessage, Cmd Msg )
init sendUrl channelName =
    { content = ""
    , sendUrl = sendUrl
    , channelName = channelName
    , chatters = []
    , autoState = Autocomplete.empty
    , showSuggestions = False
    }
        ! []


update : Msg -> UserMessage -> ( UserMessage, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model
                ! []

        RawMessage str ->
            case Twitch.Chat.Parser.parse str of
                Ok message ->
                    model
                        ! [ respondToPing model.sendUrl message ]

                Err err ->
                    model
                        ! []

        UserMessageChanged str ->
            let
                isTypingMention =
                    extractMention str
                        |> String.isEmpty
                        >> not
            in
                { model
                    | content = str
                    , showSuggestions = isTypingMention
                }
                    ! []

        SubmitUserMessage ->
            let
                message =
                    String.join ""
                        [ "PRIVMSG #"
                        , model.channelName
                        , " :"
                        , model.content
                        ]
            in
                { model
                    | content = ""
                    , autoState = Autocomplete.empty
                    , showSuggestions = False
                }
                    ! [ WebSocket.send model.sendUrl message ]

        SetAutocompleteState autoMsg ->
            let
                ( newState, maybeMsg ) =
                    Autocomplete.update updateConfig autoMsg 5 model.autoState (acceptablePeople (extractMention model.content) model.chatters)

                newModel =
                    { model | autoState = newState }
            in
                case maybeMsg of
                    Nothing ->
                        newModel ! []

                    Just updateMsg ->
                        update updateMsg newModel

        SelectPerson autocompletedPerson ->
            let
                typedMention =
                    extractMention model.content

                dropMention =
                    String.dropRight (String.length typedMention) model.content
            in
                { model
                    | content = dropMention ++ autocompletedPerson
                    , autoState = Autocomplete.empty
                    , showSuggestions = False
                }
                    ! []

        Reset toTop ->
            { model
                | autoState =
                    if toTop then
                        Autocomplete.resetToFirstItem updateConfig (acceptablePeople (extractMention model.content) model.chatters) 5 model.autoState
                    else
                        Autocomplete.resetToLastItem updateConfig (acceptablePeople (extractMention model.content) model.chatters) 5 model.autoState
            }
                ! []


acceptablePeople : String -> List Chatter -> List Chatter
acceptablePeople query chatters =
    let
        lowerQuery =
            String.toLower query
    in
        List.filter (String.contains lowerQuery << String.toLower) chatters


updateConfig : Autocomplete.UpdateConfig Msg Chatter
updateConfig =
    Autocomplete.updateConfig
        { toId = identity
        , onKeyDown = onSubmitAutocomplete
        , onTooLow = Nothing
        , onTooHigh = Nothing
        , onMouseEnter = always Nothing
        , onMouseLeave = always Nothing
        , onMouseClick = Just << SelectPerson
        , separateSelections = False
        }


viewConfig : Autocomplete.ViewConfig Chatter
viewConfig =
    let
        customizedLi keySelected mouseSelected chatter =
            { attributes =
                [ if keySelected || mouseSelected then
                    class [ Css.Highlighted, Css.Suggestion ]
                  else
                    class [ Css.Suggestion ]
                ]
            , children =
                [ text chatter ]
            }
    in
        Autocomplete.viewConfig
            { toId = identity
            , ul = [ class [ Css.Suggestions ] ]
            , li = customizedLi
            }


onSubmitAutocomplete : KeyCode -> Maybe Chatter -> Maybe Msg
onSubmitAutocomplete code maybeId =
    if code == 38 || code == 40 then
        -- Up or Down
        Nothing
    else if code == 13 || code == 9 then
        -- Enter or Tab
        Maybe.map SelectPerson maybeId
    else
        Just <| Reset False


view : UserMessage -> Html Msg
view model =
    let
        autocompleter =
            if model.showSuggestions then
                viewAutocompleter model
            else
                text ""
    in
        div
            [ class [ Css.ChatInterface ]
            ]
            [ div
                [ class [ Css.TextareaContain ]
                , preventTab
                ]
                [ viewChatbox model.content
                , autocompleter
                ]
            , viewChatButtons
            ]


extractMention : String -> String
extractMention content =
    let
        regex =
            Regex.regex "@(\\S+)$"
                |> Regex.caseInsensitive
    in
        Regex.find (Regex.AtMost 1) regex content
            |> List.head
            |> Maybe.map .match
            |> Maybe.map (String.dropLeft 1)
            |> Maybe.withDefault ""


viewAutocompleter : UserMessage -> Html Msg
viewAutocompleter model =
    Html.map SetAutocompleteState (Autocomplete.view viewConfig 5 model.autoState (acceptablePeople (extractMention model.content) model.chatters))


viewChatbox : String -> Html Msg
viewChatbox content =
    textarea
        [ placeholder "Send a message"
        , onEnter SubmitUserMessage
        , preventDefaultOnEnter
        , onInput UserMessageChanged
        , value content
        ]
        []


viewChatButtons : Html Msg
viewChatButtons =
    div
        [ class [ Css.ButtonsContainer ]
        ]
        [ button
            [ class [ Css.Submit ]
            , onClick SubmitUserMessage
            , tabindex -1
            ]
            [ text "Chat" ]
        ]


respondToPing : String -> Message -> Cmd Msg
respondToPing sendUrl message =
    case message of
        Ping content ->
            WebSocket.send sendUrl <| "PONG " ++ content

        _ ->
            Cmd.none


onEnter : Msg -> Attribute Msg
onEnter msg =
    onKey 13 { stopPropagation = False, preventDefault = False } msg


preventTab : Attribute Msg
preventTab =
    let
        options =
            { stopPropagation = False, preventDefault = True }

        filterKey code =
            if code == 9 then
                Ok code
            else
                Err "ignored input"

        decoder =
            keyCode
                |> JD.andThen (filterKey >> JDE.fromResult)
                |> JD.map (always NoOp)
    in
        onWithOptions "keydown" options decoder


onKey : KeyCode -> Html.Events.Options -> Msg -> Attribute Msg
onKey key options msg =
    let
        isKey code =
            if code == key then
                msg
            else
                NoOp
    in
        onWithOptions
            "keydown"
            options
            (JD.map isKey keyCode)


{-| A workaround to the bug in `elm-lang/virtual-dom` where capturing
the enter button does not work. So two events are used for this: `keydown` and `keypress`.
-}
preventDefaultOnEnter : Attribute Msg
preventDefaultOnEnter =
    keyCode
        |> JD.andThen
            (\code ->
                if code == 13 || code == 9 then
                    JD.succeed <| code
                else
                    JD.fail "ignore"
            )
        |> JD.map (always NoOp)
        |> onWithOptions "keypress"
            { stopPropagation = False, preventDefault = True }

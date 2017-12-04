port module Main exposing (main)

import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE


main =
    H.program
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }


type alias Model =
    { privateKey : Maybe String }


type Msg
    = SkModified String


init : ( Model, Cmd Msg )
init =
    ( { privateKey = Nothing }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "msg" msg of
        SkModified sk ->
            ( model, sendSk sk )


view : Model -> Html Msg
view model =
    H.div []
        [ H.text (toString model)
        , H.div [] [ H.input [ HE.onInput SkModified ] [] ]
        ]


port sendSk : String -> Cmd msg

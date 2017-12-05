port module Main exposing (main)

import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE


main =
    H.program
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> signature SigModified
        }


type alias Model =
    { privateKey : Maybe String
    , payload : String
    , signature : Maybe String
    }


type Msg
    = SkModified String
    | SigModified (Maybe String)


init : ( Model, Cmd Msg )
init =
    ( { privateKey = Nothing
      , payload = "hello world"
      , signature = Nothing
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "msg" msg of
        SkModified sk ->
            ( { model | privateKey = Just sk }
            , sendSk { sk = sk, payload = model.payload }
            )

        SigModified sigMaybe ->
            ( { model | signature = sigMaybe }, Cmd.none )


view : Model -> Html Msg
view model =
    H.div []
        [ H.div [] [ H.text (toString model) ]
        , H.div [] [ H.input [ HE.onInput SkModified ] [] ]
        , H.div [] [ H.text (model.signature |> Maybe.withDefault "") ]
        ]


type alias SigRequest =
    { sk : String
    , payload : String
    }


port sendSk : SigRequest -> Cmd msg


port signature : (Maybe String -> msg) -> Sub msg

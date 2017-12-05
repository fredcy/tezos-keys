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
    | PayloadModified String


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
            let
                newModel =
                    { model | privateKey = Just sk }
            in
                ( newModel, requestSignature newModel )

        PayloadModified payload ->
            let
                newModel =
                    { model | payload = payload }
            in
                ( newModel, requestSignature newModel )

        SigModified sigMaybe ->
            ( { model | signature = sigMaybe }, Cmd.none )


requestSignature : Model -> Cmd Msg
requestSignature model =
    case model.privateKey of
        Just sk ->
            sendSk { sk = sk, payload = model.payload }

        Nothing ->
            Cmd.none


view : Model -> Html Msg
view model =
    H.div []
        [ H.div [ HA.class "sk" ]
            [ H.h2 [] [ H.text "Secret key" ]
            , H.input [ HE.onInput SkModified ] []
            ]
        , H.div [ HA.class "payload" ]
            [ H.h2 [] [ H.text "Message to be signed" ]
            , H.textarea [ HE.onInput PayloadModified ] []
            ]
        , H.div [ HA.class "signature" ]
            [ H.h2 [] [ H.text "Generated signature" ]
            , H.span [] [ H.text (model.signature |> Maybe.withDefault "") ]
            ]

        --, H.div [] [ H.text (toString model) ]
        ]


type alias SigRequest =
    { sk : String
    , payload : String
    }


port sendSk : SigRequest -> Cmd msg


port signature : (Maybe String -> msg) -> Sub msg

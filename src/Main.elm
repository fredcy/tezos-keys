port module Main exposing (main)

import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE


main =
    H.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    { secretKey : Maybe String
    , payload : String
    , signature : Maybe String
    , publicKey : Maybe String
    , publicKeyHash : Maybe String
    , mnemonic : String
    , email : String
    , passphrase : String
    }


type Msg
    = SkModified String
    | SigModified (Maybe String)
    | PayloadModified String
    | PkModified (Maybe PubKeyResponse)
    | MnemonicModified String
    | EmailModified String
    | PassPhraseModified String
    | SkResponse (Maybe String)


init : ( Model, Cmd Msg )
init =
    ( { secretKey = Nothing
      , payload = "hello world"
      , signature = Nothing
      , publicKey = Nothing
      , publicKeyHash = Nothing
      , mnemonic = ""
      , email = ""
      , passphrase = ""
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ signature SigModified
        , getPk PkModified
        , skResponse SkResponse
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "msg" msg of
        SkModified sk ->
            let
                newModel =
                    { model | secretKey = Just sk }
            in
                ( newModel
                , Cmd.batch [ requestSignature newModel, requestPk newModel.secretKey ]
                )

        PayloadModified payload ->
            let
                newModel =
                    { model | payload = payload }
            in
                ( newModel, requestSignature newModel )

        SigModified sigMaybe ->
            ( { model | signature = sigMaybe }, Cmd.none )

        PkModified pkResponseMaybe ->
            case pkResponseMaybe of
                Just { pk, pkh } ->
                    ( { model | publicKey = Just pk, publicKeyHash = Just pkh }
                    , Cmd.none
                    )

                Nothing ->
                    ( { model | publicKey = Nothing, publicKeyHash = Nothing }, Cmd.none )

        MnemonicModified mnemonic ->
            let
                newModel =
                    { model | mnemonic = mnemonic }
            in
                ( newModel, requestSecretKey newModel )

        EmailModified email ->
            let
                newModel =
                    { model | email = email }
            in
                ( newModel, requestSecretKey newModel )

        PassPhraseModified passphrase ->
            let
                newModel =
                    { model | passphrase = passphrase }
            in
                ( newModel, requestSecretKey newModel )

        SkResponse skMaybe ->
            ( { model | secretKey = skMaybe }, Cmd.none )


requestSecretKey : Model -> Cmd Msg
requestSecretKey model =
    skRequest { mnemonic = model.mnemonic, email = model.email, passphrase = model.passphrase }


requestSignature : Model -> Cmd Msg
requestSignature model =
    case model.secretKey of
        Just sk ->
            sigRequest { sk = sk, payload = model.payload }

        Nothing ->
            Cmd.none


requestPk : Maybe String -> Cmd Msg
requestPk skMaybe =
    skMaybe |> Maybe.map sendSk |> Maybe.withDefault Cmd.none


view : Model -> Html Msg
view model =
    H.div []
        [ H.div [ HA.class "payload" ]
            [ H.h2 [] [ H.text "Mnemonic words" ]
            , H.textarea [ HA.class "mnemonic", HE.onInput MnemonicModified ] []
            ]
        , H.div []
            [ H.h2 [] [ H.text "Email" ]
            , H.input [ HE.onInput EmailModified, HA.class "email" ] []
            ]
        , H.div []
            [ H.h2 [] [ H.text "Passphrase" ]
            , H.input [ HE.onInput PassPhraseModified, HA.class "passphrase" ] []
            ]
        , H.div []
            [ H.h2 [] [ H.text "Secret key" ]
            , H.input
                [ HE.onInput SkModified
                , HA.class "sk"
                , HA.value (model.secretKey |> Maybe.withDefault "")
                ]
                []
            ]
        , H.div []
            [ H.h2 [] [ H.text "Public key" ]
            , H.span [ HA.class "pk" ] [ H.text (model.publicKey |> Maybe.withDefault "") ]
            ]
        , H.div []
            [ H.h2 [] [ H.text "Public key hash" ]
            , H.span [ HA.class "pkh" ] [ H.text (model.publicKeyHash |> Maybe.withDefault "") ]
            ]
        , H.div [ HA.class "payload" ]
            [ H.h2 [] [ H.text "Message to be signed" ]
            , H.textarea [ HA.class "payload", HE.onInput PayloadModified ] []
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


type alias PubKeyResponse =
    { pk : String
    , pkh : String
    }


type alias SkRequest =
    { mnemonic : String
    , email : String
    , passphrase : String
    }


port sigRequest : SigRequest -> Cmd msg


port sendSk : String -> Cmd msg


port signature : (Maybe String -> msg) -> Sub msg


port getPk : (Maybe PubKeyResponse -> msg) -> Sub msg


port skRequest : SkRequest -> Cmd msg


port skResponse : (Maybe String -> msg) -> Sub msg

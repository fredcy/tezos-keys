module Module exposing (main)

import Html as H exposing (Html)


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
    = None


init : (Model, Cmd Msg)
init =
    ( { privateKey = Nothing }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "msg" msg of
        _ ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    H.div [] [ H.text (toString model) ]

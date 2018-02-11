module Main exposing (main)

import Html
import Html.Attributes as Attrs
import Http
import Json.Decode as Decode
import Markdown


type alias Model =
    { urls : List String
    , posts : List String
    , error : Maybe Http.Error
    }


type Msg
    = NoOp
    | GetPosts (Result Http.Error (List String))
    | GotPost (Result Http.Error String)


postsUrl =
    "https://api.github.com/repos/lfarroco/elm-blog/contents/posts"


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init =
    ( Model [] [] Nothing, getBlogPosts )


view model =
    Html.div [ Attrs.class "container" ]
        [ title
        , menu menuItems
        , Html.main_ []
            [ articles model.posts ]
        ]


title =
    Html.h1 [ Attrs.class "website-title" ]
        [ Html.text "Leonardo Farroco"
        ]


menu =
    let
        item ( url, str ) =
            Html.li []
                [ Html.a
                    [ Attrs.href url
                    ]
                    [ Html.text str
                    ]
                ]

        nav =
            Html.ul [ Attrs.class "flex-row" ]
                >> List.singleton
                >> Html.nav []
    in
        List.map item >> nav


menuItems =
    [ ( "#blog", "Blog" )
    , ( "#files", "Arquivos" )
    , ( "#about", "Sobre" )
    , ( "#contact", "Contato" )
    ]


articles =
    List.map article >> Html.div []


article =
    Markdown.toHtml [ Attrs.class "markdown-body" ]
        >> List.singleton
        >> Html.article []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GetPosts (Ok urls) ->
            let
                head =
                    List.head urls
            in
                case head of
                    Just url ->
                        ( { model | urls = List.drop 1 urls }
                        , getPost url
                        )

                    Nothing ->
                        ( model, Cmd.none )

        GetPosts (Err err) ->
            ( { model | error = Just err }, Cmd.none )

        GotPost str ->
            case str of
                Ok v ->
                    ( { model | urls = List.drop 1 model.urls, posts = model.posts ++ [ v ] }
                    , case List.head model.urls of
                        Nothing ->
                            Cmd.none

                        Just url ->
                            getPost url
                    )

                Err err ->
                    ( { model | error = Just err }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


getBlogPosts : Cmd Msg
getBlogPosts =
    let
        url =
            postsUrl
    in
        Http.send GetPosts (Http.get url decodePostsUrls)


decodePostsUrls =
    Decode.list <| Decode.at [ "download_url" ] Decode.string


getPost : String -> Cmd Msg
getPost url =
    Http.send GotPost (Http.getString url)

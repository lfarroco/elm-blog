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
    | GetConfig (Result Http.Error Config)


toUrl : List String -> String
toUrl =
    String.join "/"


author : String
author =
    "lfarroco"


repo : String
repo =
    "elm-blog"


rawUrl : String
rawUrl =
    "https://raw.githubusercontent.com"


baseUrl : String
baseUrl =
    "https://api.github.com/repos/lfarroco/elm-blog"


contents : String
contents =
    "contents"


posts : String
posts =
    "posts"


branch : String
branch =
    "master"


config : String
config =
    "blog-config.json"


postsUrl : String
postsUrl =
    toUrl [ baseUrl, contents, posts ]


configUrl : String
configUrl =
    toUrl [ rawUrl, author, repo, branch, config ]


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : ( Model, Cmd Msg )
init =
    ( Model [] [] Nothing, Cmd.batch [ getBlogPosts, getConfig ] )


view : { a | posts : List String } -> Html.Html msg
view model =
    Html.div [ Attrs.class "container" ]
        [ title
        , menu menuItems
        , Html.main_ []
            [ articles model.posts ]
        ]


title : Html.Html msg
title =
    Html.h1 [ Attrs.class "website-title" ]
        [ Html.text "Leonardo Farroco"
        ]


menu : List ( String, String ) -> Html.Html msg
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


menuItems : List ( String, String )
menuItems =
    [ ( "#blog", "Blog" )
    , ( "#files", "Arquivos" )
    , ( "#about", "Sobre" )
    , ( "#contact", "Contato" )
    ]


articles : List String -> Html.Html msg
articles =
    List.map article >> Html.div []


article : String -> Html.Html msg
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

        GotPost (Ok v) ->
            ( { model | urls = List.drop 1 model.urls, posts = model.posts ++ [ v ] }
            , case List.head model.urls of
                Nothing ->
                    Cmd.none

                Just url ->
                    getPost url
            )

        GotPost (Err err) ->
            ( { model | error = Just err }, Cmd.none )

        GetConfig (Ok config) ->
            ( model, Cmd.none )

        GetConfig (Err err) ->
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


decodePostsUrls : Decode.Decoder (List String)
decodePostsUrls =
    Decode.list <| Decode.at [ "download_url" ] Decode.string


getPost : String -> Cmd Msg
getPost url =
    Http.send GotPost (Http.getString url)


getConfig : Cmd Msg
getConfig =
    Http.send GetConfig (Http.get configUrl decodeConfig)


decodeConfig : Decode.Decoder Config
decodeConfig =
    Decode.map3 Config
        (Decode.field "title" Decode.string)
        (Decode.field "posts-folder" Decode.string)
        (Decode.field "posts-per-page" Decode.int)


type alias Config =
    { title : String
    , postsFolder : String
    , postsPerPage : Int
    }

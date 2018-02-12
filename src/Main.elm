module Main exposing (main)

import Html
import Html.Attributes as Attrs
import Http
import Json.Decode as Decode
import Markdown
import Navigation

type alias Model =
    { urls : List String
    , posts : List String
    , error : Maybe Http.Error
    , config : Maybe Config
    , source : Source
    , location : Navigation.Location
    }


type Msg
    = NoOp
    | UrlChange Navigation.Location
    | GetPosts (Result Http.Error (List String))
    | GotPost (Result Http.Error String)
    | GetConfig (Result Http.Error Config)



type alias Config =
    { title : String
    , postsFolder : String
    , postsPerPage : Int
    , menuItems : List MenuItem
    }


type alias Source =
    { user : String
    , repo : String
    , branch : String
    , postsFolder : String
    }


toUrl : List String -> String
toUrl =
    String.join "/"


rawUrl : String
rawUrl =
    "https://raw.githubusercontent.com"


baseUrl : String
baseUrl =
    "https://api.github.com/repos/lfarroco/elm-blog"


config : String
config =
    "blog-config.json"


postsUrl : Source -> String
postsUrl source =
    toUrl [ baseUrl, "contents", source.postsFolder ]


configUrl : Source -> String
configUrl source =
    toUrl [ rawUrl, source.user, source.repo, source.branch, config ]


maybePrint : (a -> Html.Html msg) -> Maybe a -> Html.Html msg
maybePrint fn a =
    case a of
        Nothing ->
            Html.text ""

        Just val ->
            fn val

main : Program Source Model Msg
main =
    Navigation.programWithFlags UrlChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : Source -> Navigation.Location -> ( Model, Cmd Msg )
init source location =
    ( { urls = []
      , posts = []
      , error = Nothing
      , config = Nothing
      , source = source
      , location = location
      }
    , Cmd.batch [ getConfig source ]
    )


view : Model -> Html.Html msg
view model =
    Html.div [ Attrs.class "container" ]
        [ maybePrint title model.config
        , menu menuItems
        , Html.main_ []
            [ articles model.posts ]

        , toString model.location |> Html.text
        ]


title : Config -> Html.Html msg
title config =
    Html.h1 [ Attrs.class "website-title" ]
        [ Html.text config.title
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
    [ ( "#home", "" )
    , ( "#about", "About" )
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
        UrlChange location ->
            ({ model | location = location }, Cmd.none)

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
            ( { model | config = Just config }, getBlogPosts model.source )

        GetConfig (Err err) ->
            ( { model | error = Just err }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


getBlogPosts : Source -> Cmd Msg
getBlogPosts source =
    let
        url =
            postsUrl source
    in
        Http.send GetPosts (Http.get url decodePostsUrls)


decodePostsUrls : Decode.Decoder (List String)
decodePostsUrls =
    Decode.list <| Decode.at [ "download_url" ] Decode.string


getPost : String -> Cmd Msg
getPost url =
    Http.send GotPost (Http.getString url)


getConfig : Source -> Cmd Msg
getConfig source =
    Http.send GetConfig (Http.get (configUrl source) decodeConfig)


decodeConfig : Decode.Decoder Config
decodeConfig =
    Decode.map4 Config
        (strField "title")
        (strField "posts-folder")
        (Decode.field "posts-per-page" Decode.int)
        (Decode.field "menu-items" <| Decode.list menuItemDecoder)


menuItemDecoder : Decode.Decoder MenuItem
menuItemDecoder =
    Decode.map2 MenuItem
        (strField "slug")
        (strField "label")


strField : String -> Decode.Decoder String
strField key =
    (Decode.field key Decode.string)


type alias MenuItem =
    { slug : String
    , label : String
    }

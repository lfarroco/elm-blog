module Main exposing (main)

import Html
import Html.Attributes as Attrs
import Http
import Json.Decode as Decode
import Navigation
import UrlParser as Url exposing ((</>), s)
import Pages.ListPosts


type alias Model =
    { urls : List String
    , posts : List String
    , errors : List Http.Error
    , config : Maybe Config
    , source : Source
    , route : Maybe Route
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


type Route
    = ListPosts Int
    | ViewPost String
    | ViewPage String


toUrl : List String -> String
toUrl =
    String.join "/"


rawUrl : String
rawUrl =
    "https://raw.githubusercontent.com"


baseUrl : String
baseUrl =
    "https://api.github.com/repos"


config : String
config =
    "blog-config.json"


postsUrl : Source -> String
postsUrl source =
    toUrl [ baseUrl, source.user, source.repo, "contents", source.postsFolder ]


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
      , errors = []
      , config = Nothing
      , source = source
      , route = Url.parseHash parseRoute location
      }
    , Cmd.batch [ getConfig source ]
    )


view : Model -> Html.Html msg
view model =
    [ .config >> maybePrint title
    , .errors >> errors
    , .config >> maybePrint (.menuItems >> menu)
    , viewRoute
    , .route >> toString >> Html.text
    ]
        |> List.map (\fn -> fn model)
        |> Html.div [ Attrs.class "container" ]


viewRoute : Model -> Html.Html msg
viewRoute model =
    case model.route of
        Nothing ->
            Html.text ""

        Just route ->
            case route of
                ListPosts page ->
                    Pages.ListPosts.render model.posts page

                _ ->
                    Html.text ""


title : Config -> Html.Html msg
title config =
    Html.h1 [ Attrs.class "website-title" ]
        [ Html.text config.title
        ]


errors : List a -> Html.Html msg
errors list =
    List.map viewError list
        |> Html.div []


viewError : a -> Html.Html msg
viewError err =
    Html.div []
        [ Html.text <| toString err
        ]


menu : List MenuItem -> Html.Html msg
menu =
    let
        ifEmpty fn str = 
          if String.length str < 1 then
              str
          else
              fn str

        item menuItem =
            let
                url = ifEmpty ( (++) "#" ) menuItem.slug
            in
              Html.li []
                  [ Html.a
                      [ Attrs.href url
                      ]
                      [ Html.text menuItem.label
                      ]
                  ]

        nav =
            Html.ul [ Attrs.class "flex-row" ]
                >> List.singleton
                >> Html.nav []
    in
        List.map item >> nav

parseRoute : Url.Parser (Route -> c) c
parseRoute =
    Url.oneOf
        [ Url.map (ListPosts 0) Url.top
        , Url.map ListPosts (Url.s "posts" </> Url.int)
        , Url.map ViewPost (Url.s "post" </> Url.string)
        , Url.map ViewPage (Url.s "page" </> Url.string)
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        _ =
            Debug.log "update==>  " ( msg, model )
    in
        case msg of
            NoOp ->
                ( model, Cmd.none )

            UrlChange location ->
                let
                    route =
                        Url.parseHash parseRoute location
                in
                    ( { model | route = route }, Cmd.none )

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
                ( { model | errors = err :: model.errors }, Cmd.none )

            GotPost (Ok v) ->
                ( { model | urls = List.drop 1 model.urls, posts = model.posts ++ [ v ] }
                , case List.head model.urls of
                    Nothing ->
                        Cmd.none

                    Just url ->
                        getPost url
                )

            GotPost (Err err) ->
                ( { model | errors = err :: model.errors }, Cmd.none )

            GetConfig (Ok config) ->
                ( { model | config = Just config }, getBlogPosts model.source )

            GetConfig (Err err) ->
                ( { model | errors = err :: model.errors }, Cmd.none )


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

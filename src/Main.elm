module Main exposing (main)

import Html
import Html.Attributes as Attrs
import Html.Events exposing (..)
import Http
import Json.Decode as Decode
import Task
import Markdown

type alias Model =
  {
    urls : List String
    , posts :  List String
    , error : Maybe Http.Error

  }


type Msg
    = NoOp
    | GetPosts (Result Http.Error (List String))
    | GotPost (Result Http.Error String)



-- [
--   {
--     "name": "a.md",
--     "path": "posts/a.md",
--     "sha": "203f4c3bd83c88f419dd5fef4d80707e24435d45",
--     "size": 21,
--     "url": "https://api.github.com/repos/lfarroco/elm-blog/contents/posts/a.md?ref=master",
--     "html_url": "https://github.com/lfarroco/elm-blog/blob/master/posts/a.md",
--     "git_url": "https://api.github.com/repos/lfarroco/elm-blog/git/blobs/203f4c3bd83c88f419dd5fef4d80707e24435d45",
--     "download_url": "https://raw.githubusercontent.com/lfarroco/elm-blog/master/posts/a.md",
--     "type": "file",
--     "_links": {
--       "self": "https://api.github.com/repos/lfarroco/elm-blog/contents/posts/a.md?ref=master",
--       "git": "https://api.github.com/repos/lfarroco/elm-blog/git/blobs/203f4c3bd83c88f419dd5fef4d80707e24435d45",
--       "html": "https://github.com/lfarroco/elm-blog/blob/master/posts/a.md"
--     }
--   },
--   {
--     "name": "b.md",
--     "path": "posts/b.md",
--     "sha": "130bb00bf795b611d4a7a1263f0e844ce7b5ccdb",
--     "size": 29,
--     "url": "https://api.github.com/repos/lfarroco/elm-blog/contents/posts/b.md?ref=master",
--     "html_url": "https://github.com/lfarroco/elm-blog/blob/master/posts/b.md",
--     "git_url": "https://api.github.com/repos/lfarroco/elm-blog/git/blobs/130bb00bf795b611d4a7a1263f0e844ce7b5ccdb",
--     "download_url": "https://raw.githubusercontent.com/lfarroco/elm-blog/master/posts/b.md",
--     "type": "file",
--     "_links": {
--       "self": "https://api.github.com/repos/lfarroco/elm-blog/contents/posts/b.md?ref=master",
--       "git": "https://api.github.com/repos/lfarroco/elm-blog/git/blobs/130bb00bf795b611d4a7a1263f0e844ce7b5ccdb",
--       "html": "https://github.com/lfarroco/elm-blog/blob/master/posts/b.md"
--     }
--   }
-- ]


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
    Html.h1 []
        [ Html.text "Leonardo Farroco"
        ]


p =
    Html.text
        >> List.singleton
        >> Html.p []


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
    , ( "#Contato", "Contato" )
    ]

articles = 
  List.map article >> Html.div []
  


article =
  Markdown.toHtml [Attrs.class "post"]  
    


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
                        ( 
                          { model | urls = List.drop 1 urls }
                          , getPost url )

                    Nothing ->
                        ( model, Cmd.none )

        GetPosts (Err err) ->
            ( { model | error = Just err }, Cmd.none )

        GotPost str ->
            case str of
                Ok v ->
                    ( {model | urls = List.drop 1 model.urls, posts = model.posts ++ [ v ] }
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

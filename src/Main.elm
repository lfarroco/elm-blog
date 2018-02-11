module Main exposing (main)

import Html
import Html.Attributes as Attrs

type alias Model = Int

type Msg = NoOp

posts_url = "https://api.github.com/repos/lfarroco/elm-blog/contents/posts"

main = 
  Html.program
     {
       init = init
       , view = view
       , update = update
       ,  subscriptions = subscriptions 
    }

init = ( 2, Cmd.none)

view model = 
    Html.div [ Attrs.class "container" ]
        [ title
        , menu menuItems
        , Html.main_ []
            [ article ]
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


article =
    Html.article []
        [ Html.time [] [ Html.text "3 de dezembro de 2017" ]
        , Html.h2 [] [ Html.text "teste" ]
        , p "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean id nisi sagittis, finibus tellus sagittis, tempor diam. Maecenas lectus velit, imperdiet id finibus in, imperdiet in turpis. Integer porttitor tincidunt quam, in posuere lacus consectetur vel. Mauris eget sodales dolor. Vestibulum at semper augue, eu lobortis dolor. Sed sem urna, molestie bibendum vehicula sed, gravida nec justo. Nulla faucibus erat eget neque sodales bibendum eu sit amet justo. Curabitur dapibus diam eget felis mattis accumsan. Ut vehicula rutrum fermentum. Fusce sit amet tristique purus."
        , p "Maecenas ornare accumsan fermentum. Praesent mattis metus et sapien aliquet blandit. Duis tristique volutpat mollis. Maecenas consectetur viverra maximus. Nam in enim faucibus, blandit eros maximus, pulvinar augue. Nulla sodales pulvinar elit, et blandit ante malesuada nec. Sed luctus justo et sapien condimentum, id facilisis diam vulputate. Donec tincidunt hendrerit ex fermentum luctus. Donec vel dignissim magna, id mollis orci. Sed at orci non leo volutpat venenatis."
        , p "Curabitur risus urna, blandit sit amet sodales quis, lacinia in mauris. Integer iaculis rhoncus porttitor. Nam at est ac orci tempor bibendum nec sit amet turpis. Duis pellentesque felis eu lacus scelerisque rutrum. In et efficitur nulla. Maecenas non magna id mi viverra mattis eu a felis. Praesent sit amet risus odio. Proin fringilla, nisl et condimentum scelerisque, leo felis maximus est, ut rutrum elit mi ac nisi."
        ]

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
           case msg of
               NoOp ->
                   ( model, Cmd.none )
 

subscriptions : Model -> Sub Msg
subscriptions model =
          Sub.none
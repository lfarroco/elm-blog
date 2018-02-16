module Pages.ListPosts exposing (render)

import Html
import Html.Attributes as Attrs
import Markdown

render : List String -> a -> Html.Html msg
render posts page =
    listPosts posts

listPosts : List String -> Html.Html msg
listPosts =
    articles >> List.singleton >> Html.main_ []


articles : List String -> Html.Html msg
articles =
    List.map article >> Html.div []


article : String -> Html.Html msg
article =
    Markdown.toHtml [ Attrs.class "markdown-body" ]
        >> List.singleton
        >> Html.article []

## Accessing record fields

Records are a common way to move different types together in your application. In order to access their fields you can use the following syntaxes:

Given the record

```
font = {
    size = 12,
    family = "Sans-serif"
}

```
You can access the `size` field in the following ways:

```
--1
viewSize font = 
    Html.text (toString font.size)

--2
viewSize font = 
    Html.text <| toString font.size

--3
viewSize font = 
    toString font.size |> Html.text

--4
viewSize = 
    .size >> toString >> Html.text
```

We created four functions with the same signature, what are the pros and cons of each approach? Let's look closely:

1 - This approach uses parenthesis, in a style similar to C style languages. 

2 - The `<|` operator replaces the parenthesis. Note that the functions are still in the same order. The advantage of this operator is that you don't need to move your cursor until the end of the line just to place the closing parens.

3 - The |> operator let's you switch the order of functions and arguments. It is very useful to turns long statements into readable multi-line expressions:

`createContainer (createTableBody (createTableRow ( getClients model )))`

you can write:

```
getClients model
  |> createTableRow
  |> createTableBody
  |> createContainer
```
As Bartosz Milewski says, "Simplicity is not counted in terms of lines of code". The statement is longer, but in my humble opinion, much easier to read and reason about.

4 - 
The >> operator let's you compose functions. In the example below, you would still need to use `viewSize font` to extract the value from the record - or compose the function with another one. 
-}

It is possible to use function composition to build expressions to access the `size` or `family` attribute without mentioning the `font` variable.

```
    showSize font = 
        toString font.size |> Html.text
```
```

showSize =
    .size >> printSize >> Html.text

showFamily =
    .family >> String.toUpper >> Html.text

```

In our imaginary application the configurations are optional, so now we have to deal with a `Maybe Config` instead of type directly. 

```
.color >> getColorName

IN
When dealing with the `Maybe` type, it can be annoying to use `case` expressions all the time.

Suppose that we have a menu that receives a record with options. But this record is inside a `Maybe`:

```


menu : Maybe Options -> Html msg
menu options = 
    case options of

...

view model =
    div[][
    menu model.options
    ...
    ]


```

Unwrapping values from the `Maybe` type can be cumbersome, specially if there are lots of maybes sprinkled in your code. Also, a function takes a `Maybe` tells us that it can do two things differently (as a `Just a` or `Nothing` will be treated differently inside it).  




But there are some patterns that can help us to reduce the verbosity and make the functions more reusable.


## Maybe.map


Suppose if you have a function that takes a string and return a string, like `String.toUpper`.
Now let's suppose that you have a `Maybe String`, how you would apply this function to the value that is wrapped in maybe?
The naive way would be simply to use a `case` expression:
```
maybeToUpper : Maybe String -> Maybe String
maybeToUpper str = 
    case str of
        Just value -> Just ( String.toUpper value )
        Nothing -> Nothing
```
(I'm not using the `<|` operator to avoid complex syntax).
Writing this expression over and over can get tiresome, and if you are using the `let .. in `syntax, multiple levels of identation will start to bubble up. Luckly the default library provides `Maybe.map`:

```
hello = Just "hello"
empty = Nothing

result = Maybe.map String.toUpper hello
result == Just "HELLO"

empty = Maybe.map String.toUpper empty
empty == Nothing
```

## maybePrint



view model =
There are some ways to red
There are some tricks


"Why would I want to compose stuff, it is much easier to use the pipe operator"

Turns out that composing removes unnecessary verbosity from the code.

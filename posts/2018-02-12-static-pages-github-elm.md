# Static Pages on Github With Elm
<time datetime="2018-02-12 12:00">February 12, 2018<time>

There are many ways to publish static websites to Github, like Jest and Hexo.

As I have been using (and loving) Elm for the last months, I decided to use it to crate my blog. As I want it to have a handcraft feel, I'm limiting myself just to using Elm (which provides only client side code). In order to do this, I rely only on Github's API to list files in a folder (so that I can easily add new posts).

## Locating posts

The repository of this project has a `posts` folder with `.md` files. Each one has the content of a post.

In the `index.html` of this blog lie the few Javascript lines that boot Elm. From there I pass some flags to Elm - which allows other configurations for different projects:

```
    let flags = {
        user: "lfarroco",
        repo: "elm-blog",
        branch : "master",
        postsFolder: "posts"
    }
    Elm.Main.fullscreen(flags);
```

This tells Elm which url to look for to get the posts. After that, you just need to create markdown (.md) files in the `posts` directory.
You might ask "but what if I have 100 posts, all are going to be loaded?". To avoid that, each file can have a date in the format yyyy-mm-dd in the beggining of the file name (eg., `2018-02-12-my-filename.md`).
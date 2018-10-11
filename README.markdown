# notube: youtube without you

This is a hacked-together project to try and separate Youtube from Youtube
content. I follow a lot of great people and consume a lot of great Content™ on
Youtube, but over the years the "youtube dot com experience" has become so awful
I spent a weekend writing this.

It's a scraping script (backed by `youtube-dl`) and a small Sinatra web app that
download every video from the channels you specify, store metadata, and track
watch history in a local SQLite database.

The goal is to have this running on my NAS, scraping my favourite channels once
a day or so, allowing me to Consume Content™ without having to let Google
consume me in the process.

## Running

You'll need:

  - Reasonably up-to-date Rubby
  - `bundler`
  - Reasonably up-to-date `youtube-dl`

Then you can install dependencies:

```
$ bundle install
```

And set up your database schema. We expect a file in the project root with a
name of `library.db`:

```
$ sqlite3 library.db < schema.sql
```

Before you can run anything else, you'll need to configure the app:

```
$ cp config.yml.example config.yml
```

... and fill out an API key and list of channel URLs.

API Keys can be generated for free through the [Google Developer Console][1] (I
think that link will work), and only need access to the "Youtube Data v3 API".
You get a large number of requests per day for free (a million I think) so that
should be good for most.

[1]: https://console.developers.google.com/apis/api/youtube.googleapis.com/credentials

Then just fill out a list of URLs to Youtube channels. Both the "raw" channel
URLs (with the unreadable garbage ID) and the "pretty" usernames (for that Brand
Recognition) are supported.

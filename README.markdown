# notube: youtube without you

There is a lot of Great Content™ on Youtube, but the "youtube dot com
experience" is steadily worsening. This project is an attempt to build an
alternative to the Youtube web property, while also allowing you to archive the
content you watch, and do so privately without Google watching you in return.

## Running

You'll need:

  - Reasonably up-to-date Ruby
  - `bundler`
  - Reasonably up-to-date `youtube-dl`

Then you can install dependencies:

```
$ bundle install
```

Before you can run anything else, you'll need to configure the app:

```
$ cp config.yml.example config.yml
```

... and fill out an API key and list of channel URLs.

API Keys can be generated for free through the [Google Developer Console][1],
and only need access to the "Youtube Data v3 API". You get a large number of
requests per day for free, so that should be good for most.

[1]: https://console.developers.google.com/apis/api/youtube.googleapis.com/credentials

Then just fill out a list of URLs to Youtube channels. Both the "raw" channel
URLs (with the unreadable garbage ID) and the "pretty" usernames (for that Brand
Recognition) are supported.

To start the app, just run:

```
$ bundle exec rackup
```

The app will create and setup the database for you on-boot, and will listen on
`127.0.0.1:9292`.

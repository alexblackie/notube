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

## Testing

There is an automated test suite included. Simply invoke `rspec`:

```
$ bundle exec rspec
```

## Deployment

Notube provides no authentication and no security guarantees of any sort, so it
is recommended to only run it within a trusted network -- for example, on your
NAS at home behind a firewall, or on a machine only accessible over a VPN.

To deploy Notube, first download the latest [release][2] tarball and extract it
to your target server (we recommend `/srv/notube`).

[2]: https://github.com/alexblackie/notube/releases

Once extracted, just upload or copy in your `config.yml` with an API key and
list of subscribed channels.

Your server will need the Ruby runtime, `bundler` gem, SQLite headers, a C/C++
compiler toolchain and `youtube-dl`. We recommend installing the latest versions
of each of these.

On Ubuntu 18.04, for example:

```
$ sudo apt-get install ruby ruby-dev ruby-bundler libsqlite3-dev build-essential youtube-dl
```

On Enterprise Linux distributions, you may need to compile Ruby from source, or
find a third-party repository, as the version shipped with EL7 is quite old.

### Quick Install

All of the steps in the "Installing Manually" section can be automated for you
by running the `bin/install` script as `root` on your target server.

```
# cd /srv/notube
# bin/install
```

### Installing Manually

It is recommended to run notube as an unprivileged user (by default, `notube`).

```
$ useradd notube
$ chown -R notube /srv/notube
```

Then you can install dependencies (ensure this is done as the unprivileged user
we just created):

```
notube@localhost: $ cd /srv/notube
notube@localhost: $ bundle install --path vendor/bundle
```

A systemd unit file example is included for convenience.

  1. Copy `notube.service` to `/etc/systemd/system/notube.service`
  2. Make sure to edit `WorkingDirectory` if you didn't extract notube to
     `/srv/notube`.
  3. Run `systemctl daemon-reload` to make sure it picks up the new service.

Then you can manage notube as a regular system service:

```
$ systemctl enable notube
$ systemctl start notube
```


### Exposing on a web port

You can use a reverse proxy server such as `nginx` to expose notube on a
standard web port. For example,

```
# /etc/nginx/conf.d/notube.conf
server {
  listen 80;
  listen [::]:80;
  server_name notube.example.com;

  location / {
    proxy_buffering off;
    proxy_pass http://127.0.0.1:9292;
  }

  location ~ ^/data/ {
    expires 1w;
    add_header Cache-Control public;

    root /srv/notube/static;
  }
}
```

Note: for Enterprise Linux or other systems using SELinux, the `./static`
directory and its children will need to have a SELinux context type of
`httpd_sys_content_t` to be allowed to be served by a web server.

Stoor provides a Gollum (wiki) server with a few other bells and whistles, such as authentication against GitHub OAuth.

## Rationale

In our environment, the contents of our wiki are confidential and should not be pushed up to GitHub. We keep the wiki on
a local machine (behind a firewall), and put the wiki contents into a directory that is sync'd to box.com. (box.com is useful for confidential
data, because they will sign a HIPAA BAA.) Meanwhile, we'd like to authorize access by some means: we like GitHub Oauth,
so that we can constrain access by GitHub Organization Team membership.

## Requirements

Ruby 1.9.2 or greater.

An operating system other than Windows (because Gollum doesn't work on Windows, because grit doesn't work on Windows . . .).

Unfortunately, Stoor will no longer work on Ruby 1.8.7, because `gollum-lib` now wants Nokogiri 1.6.0 ([see?](https://github.com/gollum/gollum-lib/commit/eeb0a4a036001c7621d173e7152b91ed02b21ed0#commitcomment-4170065)), and
1.8.7 isn't supported. That's too bad, because it was nice that this would work on the system Ruby on a Mac.

## Setup

    gem install stoor

(On occasion I have had to `rbenv rehash`.)

## Usage examples

(Relax, the client id and secret below are fake.)

### The 'stoor' command

To get started, change directory to your git repo where your wiki content lives, and type the `stoor` command:

    cd wiki
    stoor

This will run your gollum wiki on port 3000, though it will decorate the footer with a message saying who
the committer is. When not authenticating against GitHub, the default options for the wiki repo is used (i.e.,
the values for the GitHub commit will be what you see in `git config -l`).

The `stoor` command is a thin wrapper around the `thin` web server, and takes all `thin` options (`-p <port>`, etc.).

If you don't have a repo yet for your wiki . . .

    mkdir mywiki
    cd mywiki
    git init .
    stoor

### Specify the Wiki repo location

    STOOR_WIKI_PATH=/Users/admin/wiki stoor

The `STOOR_WIKI_PATH` environment variable provides for locating the wiki contents in a differet repo from the
Stoor application. It is strongly advised that you do this so that you can keep your wiki code and wiki
content separate.

### GitHub authorization

Require authorization via GitHub to the GitHub application with the given client id and secret

    STOOR_GITHUB_CLIENT_ID=780ec06a331b4f61a345 STOOR_GITHUB_CLIENT_SECRET=f1e5439aff166c34f707747120acbf66ef233fc2 stoor

Access to the wiki will first run through GitHub OAuth against the app specified by the id and secret. For information
on setting up an application in GitHub and obtaining its id and secret, see <https://github.com/settings/applications/new>.
If you are running Stoor on localhost with the `stoor` command, the typical settings would be:

<table>
  <tr>
    <th> Application Name </th> <th> Main URL </th> <th> Callback URL </th>
  </tr>
  <tr>
    <td> YourAppName </td> <td> http://localhost:3000 </td><td> http://localhost:3000/auth/github/callback </td>
  </tr>
</table>

**NOTE:** No matter what your domain and port, the callback path must be `/auth/github/callback`.

**NOTE:** See also `STOOR_DOMAIN` below: The domain specified for the cookie should match the domain in your GitHub
application settings.

### Prefer a certain email domain

If there is more than one email associated with the GitHub user, prefer the one from the specified domain (otherwise the first email will be used)

    STOOR_GITHUB_EMAIL_DOMAIN=7fff.com STOOR_GITHUB_CLIENT_ID=780ec06a331b4f61a345 STOOR_GITHUB_CLIENT_SECRET=f1e5439aff166c34f707747120acbf66ef233fc2 stoor

### Require GitHub team

    STOOR_GITHUB_TEAM_ID=11155 STOOR_GITHUB_CLIENT_ID=780ec06a331b4f61a345 STOOR_GITHUB_CLIENT_SECRET=f1e5439aff166c34f707747120acbf66ef233fc2 stoor

If the user is not a member of the specified team, they aren't allowed access.

### Specify the domain (this is to ensure that cookies are set for the correct domain)

    STOOR_DOMAIN=wiki.local    # default: localhost

### Specify the cookie secret

    STOOR_SECRET="honi soit qui mal y pense"    # default: stoor

### Specify the cookie timeout

    STOOR_EXPIRE_AFTER=600    # In seconds; default: 3600

### Wide display

    STOOR_WIDE=y              # Main wiki content will take 90% of browser width; widens tables as well

## How I run it

I like having my own personal wiki. Since Apache is ubiquitous on Macs, I run the Wiki with configuration in `/etc/apache2/httpd.conf`,
and some Ruby provided by rbenv, and Passenger.

I create an extra name for 127.0.0.1 in `/etc/hosts` such as `wiki.local`. Then:

      gem install passenger
      passenger-install-apache2-module

Then in `/etc/apache2/httpd.conf`:

    LoadModule passenger_module /opt/boxen/rbenv/versions/1.9.2-p320/lib/ruby/gems/1.9.1/gems/passenger-4.0.19/buildout/apache2/mod_passenger.so
    PassengerRoot /opt/boxen/rbenv/versions/1.9.2-p320/lib/ruby/gems/1.9.1/gems/passenger-4.0.19
    PassengerDefaultRuby /opt/boxen/rbenv/versions/1.9.2-p320/bin/ruby

    NameVirtualHost *:80

    <VirtualHost *:80>
      SetEnv STOOR_GITHUB_CLIENT_ID 780ec06a331b4f61a345
      SetEnv STOOR_GITHUB_CLIENT_SECRET f1e5439aff166c34f707747120acbf66ef233fc2
      SetEnv STOOR_GITHUB_EMAIL_DOMAIN 7fff.com
      SetEnv STOOR_DOMAIN wiki.local
      SetEnv STOOR_EXPIRE_AFTER 60
      SetEnv STOOR_WIKI_PATH /Users/jgn/Dropbox/wiki
      ServerName wiki.local
      DocumentRoot "/opt/boxen/rbenv/versions/1.9.2-p320/lib/ruby/gems/1.9.1/gems/stoor-0.1.4/public"
      <Directory "/opt/boxen/rbenv/versions/1.9.2-p320/lib/ruby/gems/1.9.1/gems/stoor-0.1.4/public">
        Allow from all
        Options -MultiViews
      </Directory>
    </VirtualHost>

and finally:

    sudo apachectl -k restart

Now browse your wiki at <http://wiki.local>

## Links in the Wiki

A bit of advice: Use the MediaWiki format for links internal to your wiki. This style is recommended by GitHub (see <https://help.github.com/articles/how-do-i-add-links-to-my-wiki>).

For example, if you have a secondary page called `foo.md`, and want a link that displays "This is my foo page", write
your page link like this

```
[[This is my foo page|foo]]
```

Notice that the Gollum docs say "The page file may exist anywhere in the directory structure of the repository. Gollum does a breadth first search and uses the first match that it finds" -- So
keep your page names unique.

If you want to use relative links of the form `[Display text](wiki/other)`, don't. The wikis on GitHub do some wrangling with the base path
that are not compatible with local wikis managed by Gollum. If you peruse the Gollum documentation at <https://github.com/gollum/gollum/wiki#page-links>, you
will see that they don't describe the Markdown format at all.

(Within a Rack Builder, even if you set the Gollum `base_path` and wrap Gollum in a `map` with the same `base_path` you will find that
the displayed paths prefix URLs with an extra `base_path`.)

## Things left out

* No support for changing the "base path."
* No support for changling Gollum options - all the default options are taken

## Testing

To run the specs, create an application per "GitHub Authorization" above, and take note of the client id and client secret.

Then set up Stoor so that you are running with GitHub authorization. Authorize.

Now run the specs like so:

    STOOR_GITHUB_CLIENT_ID=780ec06a331b4f61a345 STOOR_GITHUB_CLIENT_SECRET=f1e5439aff166c34f707747120acbf66ef233fc2 bundle exec rspec


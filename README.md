This is an example of fronting Gollum with a small Sinatra app that authorizes against GitHub.

## Rationale

In our environment, the contents of our wiki are confidential and should not be pushed up to GitHub. We keep the wiki on
a local machine (behind a firewall), and put the wiki contents into a directory that is sync'd to box.com. (box.com is useful for confidential
data, because they will sign a HIPAA BAA.) Meanwhile, we'd like to authorize access by some means, so we use GitHub Oauth,
so that we can constrain access by GitHub Organization Team membership.

## Setup

    git clone git@github.com:jgn/trahald.git
    bundle

## Usage examples

(Relax, the client id and secret are fake.)

### Run gollum in the usual way

    bundle exec rackup

This will run your gollum wiki in the usual way, though it will decorate the footer with a message saying who
the committer is. When not authenticating against GitHub, the default options for the wiki repo is used (i.e.,
the values for the GitHub commit will be what you see in `git config -l`.

### Specify the Wiki repo location

    WIKI_PATH=/Users/admin/wiki bundle exec rackup

The `WIKI_PATH` environment variable provides for locating the wiki contents in a differet repo from the
Trahald application. It is strongly advised that you do this so that you can keep your wiki code and wiki
content separate.

### GitHub authorization

Require authorization via GitHub to the GitHub application with the given client id and secret

    GITHUB_CLIENT_ID=780ec06a331b4f61a345 GITHUB_CLIENT_SECRET=f1e5439aff166c34f707747120acbf66ef233fc2 bundle exec rackup

Access to the wiki will first run through GitHub OAuth against the app specified by the id and secret. For information
on setting up an application in GitHub and obtaining its id and secret, see <https://github.com/settings/applications/new>.
If you are running Trahald on localhost with Rackup, the typical settings would be:

<table>
  <tr>
    <th>Application Name</th><th>Main URL</th><th>Callback URL</th>
  </tr>
  <tr>
    <td>YourAppName</td><td>http://localhost:9292</td><td>http://localhost:9292/auth/github/callback</td>
  </tr>
</table>

**NOTE:** No matter what your domain and port, the callback path must be `/auth/github/callback`.

**NOTE:** See also `TRAHALD_DOMAIN` below: The domain specified for the cookie should match the domain in your GitHub
application settings.

### Prefer a certain email domain

If there is more than one email associated with the GitHub user, prefer the one from the specified domain (otherwise the first email will be used)

    GITHUB_EMAIL_DOMAIN=7fff.com GITHUB_CLIENT_ID=780ec06a331b4f61a345 GITHUB_CLIENT_SECRET=f1e5439aff166c34f707747120acbf66ef233fc2 bundle exec rackup

### Require GitHub team

    GITHUB_TEAM_ID=11155 GITHUB_CLIENT_ID=780ec06a331b4f61a345 GITHUB_CLIENT_SECRET=f1e5439aff166c34f707747120acbf66ef233fc2 bundle exec rackup

If the user is not a member of the specified team, they aren't allowed access.

### Specify the domain (this is to ensure that cookies are set for the correct domain)

    TRAHALD_DOMAIN=wiki.local    # default: localhost

### Specify the cookie secret

    TRAHALD_SECRET="honi soit qui mal y pense"    # default: trahald

### Specify the cookie timeout

    TRAHALD_EXPIRE_AFTER=600    # In seconds; default: 3600


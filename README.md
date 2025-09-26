# Shard

## Setup for Development

To start your Phoenix server (assumes Debian-family Linux):

* Install the deb packages: `postgresql postgresql-client libpq-dev 
  build-essential autoconf m4 libncurses5-dev libpng-dev libssh-dev 
  unixodbc-dev xsltproc fop libxml2-utils libncurses-dev default-jdk`
* Install Erlang, Elixir, and NodeJS using [asdf](https://asdf-vm.com/); see
  `scripts/setup-asdf.sh` for hints.
* Run `sudo scripts/setup-dev-postgres.sh` to setup the dev DB. This script
probably installs a RAT, so read it first.
* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix


## Deploying to a VPS

- Get VPS
- Get domain, point host at IP of VPS (use A record or a
  CNAME record).
- Create application user: `sudo adduser shard`
  - Set password to something unmemorable.
- Enable remote ssh key login.
  - (from local machine) ssh-copy-id shard@vps-host
- Log in as new user via ssh, and git clone the repository to
  that home directory.
- Set up asdf, erlang, elixir, nodejs.
  - Should almost be able to just run scripts/setup-asdf.sh
  - Read the script for the apt-get command to install build
    deps for erlang.
  - Remember to add lines to ~/.bashrc
- Set up nginx config file.
  - Template in notes/deploy/shard.nginx
  - Change server_name
  - Put in /etc/nginx/sites-available
  - Symlink into /etc/nginx/sites-enabled
  - Restart nginx
  - You should get a 502 error when loading the page at
    this point.
- Set up systemd service file.
  - Template in notes/deploy/shard.service
  - Read the comment at the top.
  - The enable-linger thing gets run as root once: 
    `loginctl enable-linger`
- Put your ~/prod-env.sh into place.
  - Template in notes/deploy/prod-env.sh
  - Generate a SECRET_KEY_BASE with `mix phx.gen.secret`
- Set up the database.
  - Make sure you have postgres installed.
  - As the postgres system user, run `createuser shard`.
  - Set a random, long password for the new DB user.
  - Put that in your application env file ~/prod-env.sh
  - Run `. ~/prod-env.sh ; mix ecto.setup` to create your
    db.
- Testing: Run `scripts/start.sh` to start the app
  in your terminal window. This lets you see live logs,
  but will stop working if you disconnect.
- Now you should be able to run `scripts/deploy-user.sh`
  to build a release and start the app.
- Run `sudo apt install certbot python3-certbot-nginx` 
  then `sudo certbot` to enable https.
- When you discover that ET&S is blocking your new domain,
  submit a help desk ticket and mention that your domain
  was registered for Software Engineering with Tuck at PSU.



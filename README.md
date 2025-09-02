# Shard

## Setup for Development

To start your Phoenix server (assumes Debian-family Linux):

* Install the deb packages: `postgresql postgresql-client libpq-dev 
  build-essential autoconf m4 libncurses5-dev libpng-dev libssh-dev 
  unixodbc-dev xsltproc fop libxml2-utils libncurses-dev default-jdk`
* Install Erlang, Elixir, and NodeJS using [asdf](https://asdf-vm.com/).
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

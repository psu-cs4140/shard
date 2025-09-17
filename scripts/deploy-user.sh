#!/bin/bash

if [[ -e ~/.asdf/asdf.sh ]]; then
    .  ~/.asdf/asdf.sh
fi

. ~/prod-env.sh

systemctl --user stop shard

echo "Building..."

mkdir -p priv/static

mix deps.get
mix compile
mix ecto.migrate

export NODEBIN=`pwd`/assets/node_modules/.bin
export PATH="$PATH:$NODEBIN"

(cd assets && pnpm install)
# (cd assets && webpack --mode production)
mix phx.digest
mix assets.deploy

echo "Generating release..."
mix release --overwrite

echo "Starting app..."

#_build/prod/rel/shard/bin/shard start

systemctl --user start shard

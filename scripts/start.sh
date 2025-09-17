#!/bin/bash

if [[ -e ~/.asdf/asdf.sh ]]; then
    .  ~/.asdf/asdf.sh
fi

. ~/prod-env.sh

_build/prod/rel/shard/bin/shard start

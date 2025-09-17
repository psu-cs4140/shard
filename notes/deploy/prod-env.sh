export MIX_ENV=prod
export PHX_SERVER=true
export PHX_HOST=shard.homework.quest
export PORT=4242
export DATABASE_URL=ecto://shard:[pwgen 14 1]@localhost/shard_prod
export SECRET_KEY_BASE=[mix phx.gen.secret]

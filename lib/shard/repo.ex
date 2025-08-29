defmodule Shard.Repo do
  use Ecto.Repo,
    otp_app: :shard,
    adapter: Ecto.Adapters.Postgres
end

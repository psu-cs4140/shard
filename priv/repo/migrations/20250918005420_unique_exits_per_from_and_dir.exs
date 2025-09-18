defmodule Shard.Repo.Migrations.UniqueExitsPerFromAndDir do
  use Ecto.Migration

  def change do
    create unique_index(:exits, [:from_room_id, :dir])
  end
end

defmodule Shard.Repo.Migrations.AddUniqueIndexDoorsFromRoomIdDirection do
  use Ecto.Migration

  def change do
    execute "CREATE UNIQUE INDEX IF NOT EXISTS doors_from_room_id_direction_idx ON doors (from_room_id, direction)"
  end
end

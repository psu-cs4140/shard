defmodule Shard.Repo.Migrations.AddUniqueIndexDoorsFromRoomIdDirection do
  use Ecto.Migration

  def change do
    create unique_index(:doors, [:from_room_id, :direction])
  end
end

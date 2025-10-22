defmodule Shard.Repo.Migrations.AddUniqueIndexDoorsFromRoomIdDirection do
  use Ecto.Migration

  def change do
    unless index_exists?(:doors, [:from_room_id, :direction]) do
      create unique_index(:doors, [:from_room_id, :direction])
    end
  end
end

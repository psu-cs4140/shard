defmodule Shard.Repo.Migrations.AddIndexesToRoomsAndExits do
  use Ecto.Migration

  def change do
    # If the unique index already exists, this will no-op
    create_if_not_exists index(:rooms, [:slug], unique: true, name: :rooms_slug_index)

    # Safe either way
    create_if_not_exists index(:exits, [:from_room_id])
    create_if_not_exists index(:exits, [:to_room_id])
  end
end

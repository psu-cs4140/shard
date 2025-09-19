defmodule Shard.Repo.Migrations.AddFromRoomIdToExits do
  use Ecto.Migration

  def change do
    alter table(:exits) do
      # If your rooms.id is :integer (not default :bigint), add: references(:rooms, type: :integer)
      add :from_room_id, references(:rooms, on_delete: :restrict)
    end

    create_if_not_exists index(:exits, [:from_room_id])
  end
end

defmodule Shard.Repo.Migrations.DropLegacyFromIdOnExits do
  use Ecto.Migration

  def change do
    alter table(:exits) do
      remove :from_id
    end

    create_if_not_exists index(:exits, [:from_room_id])
    create_if_not_exists index(:exits, [:to_id])
  end
end

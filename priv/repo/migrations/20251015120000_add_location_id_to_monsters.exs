defmodule Shard.Repo.Migrations.AddLocationIdToMonsters do
  use Ecto.Migration

  def change do
    # Column already exists, just ensure index is created
    create_if_not_exists index(:monsters, [:location_id])
  end
end

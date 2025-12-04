defmodule Shard.Repo.Migrations.CreateChoppingInventories do
  use Ecto.Migration

  def change do
    create table(:chopping_inventories) do
      add :character_id, references(:characters, on_delete: :delete_all), null: false
      add :wood, :integer, default: 0, null: false
      add :sticks, :integer, default: 0, null: false
      add :seeds, :integer, default: 0, null: false
      add :mushrooms, :integer, default: 0, null: false
      add :resin, :integer, default: 0, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:chopping_inventories, [:character_id])
  end
end

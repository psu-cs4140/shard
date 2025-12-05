defmodule Shard.Repo.Migrations.CreateMiningInventories do
  use Ecto.Migration

  def change do
    create table(:mining_inventories) do
      add :character_id, references(:characters, on_delete: :delete_all), null: false
      add :stone, :integer, default: 0, null: false
      add :coal, :integer, default: 0, null: false
      add :copper, :integer, default: 0, null: false
      add :iron, :integer, default: 0, null: false
      add :gems, :integer, default: 0, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:mining_inventories, [:character_id])
  end
end

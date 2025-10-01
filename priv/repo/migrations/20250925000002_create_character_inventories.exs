defmodule Shard.Repo.Migrations.CreateCharacterInventories do
  use Ecto.Migration

  def change do
    create table(:character_inventories) do
      add :character_id, references(:characters, on_delete: :delete_all), null: false
      add :item_id, references(:items, on_delete: :delete_all), null: false
      add :quantity, :integer, default: 1
      add :slot_position, :integer
      add :equipped, :boolean, default: false
      add :equipment_slot, :string

      timestamps(type: :utc_datetime)
    end

    create index(:character_inventories, [:character_id])
    create index(:character_inventories, [:item_id])
    create unique_index(:character_inventories, [:character_id, :slot_position])
    create unique_index(:character_inventories, [:character_id, :equipment_slot], where: "equipped = true")
  end
end

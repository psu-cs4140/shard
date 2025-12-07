defmodule Shard.Repo.Migrations.AddCurrentDurabilityToCharacterInventory do
  use Ecto.Migration

  def change do
    alter table(:character_inventories) do
      add :current_durability, :integer
    end
  end
end

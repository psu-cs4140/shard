defmodule Shard.Repo.Migrations.AddCurrentDurabilityToCharacterEquipment do
  use Ecto.Migration

  def change do
    alter table(:character_equipment) do
      add :current_durability, :integer
    end
  end
end

defmodule Shard.Repo.Migrations.AddPetLevelsToCharacters do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      add :pet_rock_level, :integer, default: 1, null: false
      add :pet_rock_xp, :integer, default: 0, null: false
      add :shroomling_level, :integer, default: 1, null: false
      add :shroomling_xp, :integer, default: 0, null: false
    end
  end
end

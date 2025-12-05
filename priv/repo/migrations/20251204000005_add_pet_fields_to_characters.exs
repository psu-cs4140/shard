defmodule Shard.Repo.Migrations.AddPetFieldsToCharacters do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      add :has_pet_rock, :boolean, default: false, null: false
      add :has_shroomling, :boolean, default: false, null: false
    end
  end
end

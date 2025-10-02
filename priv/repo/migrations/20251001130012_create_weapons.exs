defmodule Shard.Repo.Migrations.CreateWeapons do
  use Ecto.Migration

  def change do
    create table(:weapons) do
      add :name, :string
      add :damage, :integer
      add :gold_value, :integer
      add :description, :string
      add :weapon_class_id, references(:weapon_classes, on_delete: :nothing)
      add :rarity_id, references(:rarities, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:weapons, [:weapon_class_id])
    create index(:weapons, [:rarity_id])
  end
end

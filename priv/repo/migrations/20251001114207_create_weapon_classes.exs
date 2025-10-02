defmodule Shard.Repo.Migrations.CreateWeaponClasses do
  use Ecto.Migration

  def change do
    create table(:weapon_classes) do
      add :name, :string
      add :damage_type_id, references(:damage_types, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:weapon_classes, [:damage_type_id])
  end
end

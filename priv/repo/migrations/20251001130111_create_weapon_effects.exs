defmodule Shard.Repo.Migrations.CreateWeaponEffects do
  use Ecto.Migration

  def change do
    create table(:weapon_effects) do
      add :weapon_id, references(:weapons, on_delete: :nothing)
      add :effect_id, references(:effects, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:weapon_effects, [:weapon_id])
    create index(:weapon_effects, [:effect_id])
  end
end

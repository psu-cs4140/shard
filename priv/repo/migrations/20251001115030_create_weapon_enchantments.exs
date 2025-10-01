defmodule Shard.Repo.Migrations.CreateWeaponEnchantments do
  use Ecto.Migration

  def change do
    create table(:weapon_enchantments) do
      add :weapon_id, references(:weapons, on_delete: :nothing)
      add :enchantment_id, references(:enchantments, on_delete: :nothing)
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:weapon_enchantments, [:user_id])

    create index(:weapon_enchantments, [:weapon_id])
    create index(:weapon_enchantments, [:enchantment_id])
  end
end

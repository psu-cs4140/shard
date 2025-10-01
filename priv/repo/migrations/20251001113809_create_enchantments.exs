defmodule Shard.Repo.Migrations.CreateEnchantments do
  use Ecto.Migration

  def change do
    create table(:enchantments) do
      add :name, :string
      add :modifier_type, :string
      add :modifier_value, :string
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:enchantments, [:user_id])
  end
end

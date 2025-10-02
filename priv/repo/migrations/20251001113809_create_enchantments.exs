defmodule Shard.Repo.Migrations.CreateEnchantments do
  use Ecto.Migration

  def change do
    create table(:enchantments) do
      add :name, :string
      add :modifier_type, :string
      add :modifier_value, :string

      timestamps(type: :utc_datetime)
    end
  end
end

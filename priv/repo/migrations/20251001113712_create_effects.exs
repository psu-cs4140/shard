defmodule Shard.Repo.Migrations.CreateEffects do
  use Ecto.Migration

  def change do
    create table(:effects) do
      add :name, :string
      add :modifier_type, :string
      add :modifier_value, :integer

      timestamps(type: :utc_datetime)
    end
  end
end

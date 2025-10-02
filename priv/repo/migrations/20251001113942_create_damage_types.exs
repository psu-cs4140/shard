defmodule Shard.Repo.Migrations.CreateDamageTypes do
  use Ecto.Migration

  def change do
    create table(:damage_types) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end

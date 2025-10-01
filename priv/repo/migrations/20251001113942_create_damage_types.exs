defmodule Shard.Repo.Migrations.CreateDamageTypes do
  use Ecto.Migration

  def change do
    create table(:damage_types) do
      add :name, :string
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:damage_types, [:user_id])
  end
end

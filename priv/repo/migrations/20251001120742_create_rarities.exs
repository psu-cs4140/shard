defmodule Shard.Repo.Migrations.CreateRarities do
  use Ecto.Migration

  def change do
    create table(:rarities) do
      add :name, :string
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:rarities, [:user_id])
  end
end

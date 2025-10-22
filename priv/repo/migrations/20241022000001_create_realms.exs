defmodule Shard.Repo.Migrations.CreateRealms do
  use Ecto.Migration

  def change do
    create table(:realms) do
      add :name, :string, null: false
      add :description, :text
      add :is_active, :boolean, default: true, null: false

      timestamps()
    end

    create unique_index(:realms, [:name])
  end
end

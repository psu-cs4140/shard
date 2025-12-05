defmodule Shard.Repo.Migrations.CreateUserZoneProgress do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:user_zone_progress) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :zone_id, references(:zones, on_delete: :delete_all), null: false
      add :progress, :string, null: false, default: "locked"

      timestamps()
    end

    create_if_not_exists unique_index(:user_zone_progress, [:user_id, :zone_id])
    create_if_not_exists index(:user_zone_progress, [:user_id])
    create_if_not_exists index(:user_zone_progress, [:zone_id])
  end
end

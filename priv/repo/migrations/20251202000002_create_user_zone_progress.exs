defmodule Shard.Repo.Migrations.CreateUserZoneProgress do
  use Ecto.Migration

  def change do
    # Table already exists, only create indexes if they don't exist
    create_if_not_exists unique_index(:user_zone_progress, [:user_id, :zone_id])
    create_if_not_exists index(:user_zone_progress, [:user_id])
    create_if_not_exists index(:user_zone_progress, [:zone_id])
  end
end

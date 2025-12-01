defmodule Shard.Repo.Migrations.CreatePlayerZones do
  use Ecto.Migration

  def change do
    create table(:player_zones) do
      add :zone_name, :string, null: false
      add :instance_type, :string, null: false
      add :zone_instance_id, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :zone_id, references(:zones, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:player_zones, [:user_id, :zone_name, :instance_type],
      name: :player_zones_user_zone_instance_index
    )
    create index(:player_zones, [:user_id])
    create index(:player_zones, [:zone_name])
    create index(:player_zones, [:instance_type])
    create index(:player_zones, [:zone_instance_id])
  end
end

defmodule Shard.Repo.Migrations.AddZoneIdToZones do
  use Ecto.Migration

  def change do
    alter table(:zones) do
      add :zone_id, :string
    end

    create unique_index(:zones, [:zone_id])
  end
end

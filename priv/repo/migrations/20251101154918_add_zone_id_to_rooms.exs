defmodule Shard.Repo.Migrations.AddZoneIdToRooms do
  use Ecto.Migration

  def up do
    # Add zone_id column (nullable for backwards compatibility with existing data)
    alter table(:rooms) do
      add :zone_id, references(:zones, on_delete: :delete_all), null: true
    end

    # Create index for zone_id
    create index(:rooms, [:zone_id])

    # Drop old unique constraint on coordinates only
    drop_if_exists unique_index(:rooms, [:x_coordinate, :y_coordinate, :z_coordinate])

    # Create new unique constraint on zone_id + coordinates
    # This allows same coordinates in different zones
    create unique_index(:rooms, [:zone_id, :x_coordinate, :y_coordinate, :z_coordinate],
             name: :rooms_zone_coordinates_index
           )
  end

  def down do
    # Drop the zone-scoped coordinate constraint
    drop_if_exists unique_index(:rooms, [:zone_id, :x_coordinate, :y_coordinate, :z_coordinate],
                     name: :rooms_zone_coordinates_index
                   )

    # Recreate the old global coordinate constraint
    create unique_index(:rooms, [:x_coordinate, :y_coordinate, :z_coordinate])

    # Drop the zone_id index
    drop_if_exists index(:rooms, [:zone_id])

    # Drop zone_id column
    alter table(:rooms) do
      remove :zone_id
    end
  end
end

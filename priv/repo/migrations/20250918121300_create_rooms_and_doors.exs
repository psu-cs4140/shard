defmodule Shard.Repo.Migrations.CreateRoomsAndDoors do
  use Ecto.Migration

  def change do
    # Check if rooms table exists before creating it
    unless table_exists?(:rooms) do
      create table(:rooms) do
        add :name, :string, null: false
        add :description, :text
        add :x_coordinate, :integer, default: 0
        add :y_coordinate, :integer, default: 0
        add :z_coordinate, :integer, default: 0
        add :is_public, :boolean, default: true
        add :room_type, :string, default: "standard"
        add :properties, :map, default: %{}
        
        timestamps(type: :utc_datetime)
      end

      create unique_index(:rooms, [:name])
      create index(:rooms, [:x_coordinate, :y_coordinate, :z_coordinate])
    end

    # Check if doors table exists before creating it
    unless table_exists?(:doors) do
      create table(:doors) do
        add :name, :string
        add :description, :text
        add :from_room_id, references(:rooms, on_delete: :delete_all), null: false
        add :to_room_id, references(:rooms, on_delete: :delete_all), null: false
        add :direction, :string, null: false # north, south, east, west, up, down, etc.
        add :is_locked, :boolean, default: false
        add :key_required, :string
        add :door_type, :string, default: "standard"
        add :properties, :map, default: %{}
        
        timestamps(type: :utc_datetime)
      end

      create index(:doors, [:from_room_id])
      create index(:doors, [:to_room_id])
      create index(:doors, [:direction])
      create unique_index(:doors, [:from_room_id, :direction])
    end
  end

  defp table_exists?(table_name) do
    query = "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = $1)"
    case Ecto.Adapters.SQL.query(Shard.Repo, query, [Atom.to_string(table_name)]) do
      {:ok, %{rows: [[true]]}} -> true
      {:ok, %{rows: [[false]]}} -> false
      _ -> false
    end
  end
end

defmodule Shard.Repo.Migrations.AddLocationIdToMonsters do
  use Ecto.Migration

  def change do
    # Add the location_id column to monsters table
    alter table(:monsters) do
      add :location_id, references(:rooms, on_delete: :delete_all)
    end

    # Create index on location_id
    create index(:monsters, [:location_id])
  end
end

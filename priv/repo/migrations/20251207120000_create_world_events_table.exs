defmodule Shard.Repo.Migrations.CreateWorldEventsTable do
  use Ecto.Migration

  def change do
    create table(:world_events) do
      add :event_type, :string, null: false
      add :title, :string, null: false
      add :description, :text, null: false
      add :room_id, references(:rooms, on_delete: :delete_all)
      add :is_active, :boolean, default: true, null: false
      add :duration_minutes, :integer
      add :started_at, :utc_datetime
      add :ended_at, :utc_datetime
      add :data, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:world_events, [:event_type])
    create index(:world_events, [:room_id])
    create index(:world_events, [:is_active])
    create index(:world_events, [:started_at])
  end
end

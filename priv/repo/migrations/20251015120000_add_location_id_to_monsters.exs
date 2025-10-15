defmodule Shard.Repo.Migrations.AddLocationIdToMonsters do
  use Ecto.Migration

  def change do
    alter table(:monsters) do
      add :location_id, references(:rooms, on_delete: :nilify_all), null: true
    end

    create index(:monsters, [:location_id])
  end
end

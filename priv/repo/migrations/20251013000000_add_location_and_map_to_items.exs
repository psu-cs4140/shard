defmodule Shard.Repo.Migrations.AddLocationAndMapToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :location, :string
      add :map, :string
    end

    create index(:items, [:map])
    create index(:items, [:location])
    create index(:items, [:map, :location])
  end
end

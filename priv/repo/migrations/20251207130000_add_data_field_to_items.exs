defmodule Shard.Repo.Migrations.AddDataFieldToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :data, :map, default: %{}
    end
  end
end

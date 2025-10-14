defmodule Shard.Repo.Migrations.AddPickupToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :pickup, :boolean, default: true, null: false
    end
  end
end

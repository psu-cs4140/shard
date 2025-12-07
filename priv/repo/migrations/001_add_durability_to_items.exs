defmodule Shard.Repo.Migrations.AddDurabilityToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :max_durability, :integer
      add :durability_enabled, :boolean, default: false
    end
  end
end

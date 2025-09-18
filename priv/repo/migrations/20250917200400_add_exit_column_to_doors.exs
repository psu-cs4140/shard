defmodule Shard.Repo.Migrations.AddExitColumnToDoors do
  use Ecto.Migration

  def change do
    alter table(:doors) do
      add :exit, :boolean, default: false, null: false
    end
  end
end

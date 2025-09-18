defmodule Shard.Repo.Migrations.CreateDoorsTable do
  use Ecto.Migration

  def change do
    create table(:doors) do
      add :is_open, :boolean, default: false, null: false
      add :is_locked, :boolean, default: false, null: false
      timestamps(type: :utc_datetime)
    end
  end
end

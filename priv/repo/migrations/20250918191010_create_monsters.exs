defmodule Shard.Repo.Migrations.CreateMonsters do
  use Ecto.Migration

  def change do
    create table(:monsters) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :species, :string
      add :description, :text
      add :level, :integer, null: false, default: 1
      add :hp, :integer, null: false, default: 10
      add :attack, :integer, null: false, default: 2
      add :defense, :integer, null: false, default: 1
      add :speed, :integer, null: false, default: 1
      add :xp_drop, :integer, null: false, default: 5
      add :element, :string
      add :ai, :string
      add :spawn_rate, :integer, null: false, default: 10
      add :room_id, references(:rooms, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:monsters, [:slug])
    create unique_index(:monsters, [:name])
    create index(:monsters, [:room_id])
  end
end

defmodule Shard.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create table(:characters) do
      add :name, :string, null: false
      add :level, :integer, default: 1
      add :class, :string, null: false
      add :race, :string, null: false
      add :health, :integer, default: 100
      add :mana, :integer, default: 50
      add :strength, :integer, default: 10
      add :dexterity, :integer, default: 10
      add :intelligence, :integer, default: 10
      add :constitution, :integer, default: 10
      add :experience, :integer, default: 0
      add :gold, :integer, default: 0
      add :location, :string, default: "starting_town"
      add :description, :text
      add :is_active, :boolean, default: true
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:characters, [:user_id])
    create unique_index(:characters, [:name])
  end
end

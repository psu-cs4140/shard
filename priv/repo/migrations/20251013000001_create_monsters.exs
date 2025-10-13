defmodule Shard.Repo.Migrations.CreateMonsters do
  use Ecto.Migration

  def change do
    create table(:monsters) do
      add :name, :string, null: false
      add :race, :string, null: false
      add :health, :integer, null: false
      add :max_health, :integer, null: false
      add :attack_damage, :integer, null: false
      add :potential_loot_drops, :map, default: %{}
      add :xp_amount, :integer, null: false
      add :level, :integer, default: 1, null: false
      add :description, :text
      add :x_location, :integer
      add :y_location, :integer

      timestamps(type: :utc_datetime)
    end

    create index(:monsters, [:location_id])
  end
end

defmodule Shard.Repo.Migrations.AddSpecialDamageToMonsters do
  use Ecto.Migration

  def change do
    alter table(:monsters) do
      add :special_damage_type_id, references(:damage_types, on_delete: :nilify_all)
      add :special_damage_amount, :integer, default: 0
      add :special_damage_duration, :integer, default: 0
      add :special_damage_chance, :integer, default: 100
    end
  end
end

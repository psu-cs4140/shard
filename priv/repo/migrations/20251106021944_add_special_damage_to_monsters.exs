defmodule Shard.Repo.Migrations.AddSpecialDamageToMonsters do
  use Ecto.Migration

  def change do
    # Add columns without references first to avoid constraint issues
    alter table(:monsters) do
      add_if_not_exists :special_damage_type_id, :integer
      add_if_not_exists :special_damage_amount, :integer, default: 0
      add_if_not_exists :special_damage_duration, :integer, default: 0
      add_if_not_exists :special_damage_chance, :integer, default: 100
    end

    # Create the foreign key constraint only if it doesn't exist
    execute """
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'monsters_special_damage_type_id_fkey' 
        AND conrelid = 'monsters'::regclass
      ) THEN
        ALTER TABLE monsters 
        ADD CONSTRAINT monsters_special_damage_type_id_fkey 
        FOREIGN KEY (special_damage_type_id) 
        REFERENCES damage_types(id) ON DELETE SET NULL;
      END IF;
    END
    $$;
    """
  end
end

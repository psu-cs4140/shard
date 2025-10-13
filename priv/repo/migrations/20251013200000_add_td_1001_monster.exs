defmodule Shard.Repo.Migrations.AddTd1001Monster do
  use Ecto.Migration

  def up do
    # Insert the TD_1001 monster
    execute """
    INSERT INTO monsters (name, xp_drop, x_location, y_location, inserted_at, updated_at)
    VALUES ('TD_1001', 1001, 1, 1, NOW(), NOW())
    """
  end

  def down do
    # Remove the TD_1001 monster
    execute """
    DELETE FROM monsters WHERE name = 'TD_1001'
    """
  end
end

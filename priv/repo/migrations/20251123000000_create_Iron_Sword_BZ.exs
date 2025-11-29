defmodule Shard.Repo.Migrations.CreateIronSwordBZ do
  use Ecto.Migration

  def up do
    # Create the Spectral Iron Edge item
    execute """
    INSERT INTO items (
      name,
      description,
      item_type,
      rarity,
      value,
      weight,
      stackable,
      max_stack_size,
      equipment_slot,
      pickup,
      inserted_at,
      updated_at
    ) VALUES (
      'Spectral Iron Edge',
      'A sturdy iron sword, its edge worn but reliable. Though simple in design, it carries the mark of a skilled smith and feels well-balanced in the hand.',
      'weapon',
      'uncommon',
      100,
      0.1,
      true,
      1,
      null,
      true,
      NOW(),
      NOW()
    );
    """
  end

  def down do
    execute "DELETE FROM items WHERE name = 'Spectral Iron Edge';"
  end
end

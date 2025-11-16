defmodule Shard.Repo.Migrations.CreateBoneZoneKeyItem do
  use Ecto.Migration

  def up do
    # Create the Bone Zone Key item
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
      properties,
      pickup,
      inserted_at,
      updated_at
    ) VALUES (
      'Bone Zone Key',
      'An ancient skeletal key that glows with eerie blue light. This key grants access to deeper areas of the Bone Zone.',
      'key',
      'rare',
      100,
      0.1,
      true,
      1,
      null,
      '{"zone_access": "bone_zone_deep", "key_type": "zone_key"}',
      true,
      NOW(),
      NOW()
    );
    """
  end

  def down do
    execute "DELETE FROM items WHERE name = 'Bone Zone Key';"
  end
end

defmodule Shard.Repo.Migrations.InsertDoorsData2 do
  use Ecto.Migration

  def up do
    # Insert door data
    doors_data = [
      %{
        id: 89,
        direction: "west",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 31,
        to_room_id: 35,
        inserted_at: ~U[2025-11-02 18:26:28Z],
        updated_at: ~U[2025-11-02 18:26:28Z]
      },
      %{
        id: 90,
        direction: "east",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 35,
        to_room_id: 31,
        inserted_at: ~U[2025-11-02 18:26:28Z],
        updated_at: ~U[2025-11-02 18:26:28Z]
      },
      %{
        id: 91,
        direction: "north",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 35,
        to_room_id: 46,
        inserted_at: ~U[2025-11-02 18:26:53Z],
        updated_at: ~U[2025-11-02 18:26:53Z]
      },
      %{
        id: 92,
        direction: "south",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 46,
        to_room_id: 35,
        inserted_at: ~U[2025-11-02 18:26:53Z],
        updated_at: ~U[2025-11-02 18:26:53Z]
      },
      %{
        id: 93,
        direction: "west",
        is_locked: true,
        key_required: "Master Bedoom Key",
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 34,
        to_room_id: 47,
        inserted_at: ~U[2025-11-02 18:27:28Z],
        updated_at: ~U[2025-11-02 18:27:28Z]
      },
      %{
        id: 94,
        direction: "east",
        is_locked: true,
        key_required: "Master Bedoom Key",
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 47,
        to_room_id: 34,
        inserted_at: ~U[2025-11-02 18:27:28Z],
        updated_at: ~U[2025-11-02 18:27:28Z]
      },
      %{
        id: 95,
        direction: "east",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 33,
        to_room_id: 36,
        inserted_at: ~U[2025-11-02 18:28:41Z],
        updated_at: ~U[2025-11-02 18:28:41Z]
      },
      %{
        id: 96,
        direction: "west",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 36,
        to_room_id: 33,
        inserted_at: ~U[2025-11-02 18:28:41Z],
        updated_at: ~U[2025-11-02 18:28:41Z]
      },
      %{
        id: 97,
        direction: "east",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 36,
        to_room_id: 37,
        inserted_at: ~U[2025-11-02 18:28:54Z],
        updated_at: ~U[2025-11-02 18:28:54Z]
      },
      %{
        id: 98,
        direction: "west",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 37,
        to_room_id: 36,
        inserted_at: ~U[2025-11-02 18:28:54Z],
        updated_at: ~U[2025-11-02 18:28:54Z]
      },
      %{
        id: 99,
        direction: "east",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 37,
        to_room_id: 38,
        inserted_at: ~U[2025-11-02 18:30:07Z],
        updated_at: ~U[2025-11-02 18:30:07Z]
      },
      %{
        id: 100,
        direction: "west",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 38,
        to_room_id: 37,
        inserted_at: ~U[2025-11-02 18:30:07Z],
        updated_at: ~U[2025-11-02 18:30:07Z]
      },
      %{
        id: 101,
        direction: "north",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 38,
        to_room_id: 39,
        inserted_at: ~U[2025-11-02 18:30:27Z],
        updated_at: ~U[2025-11-02 18:30:27Z]
      },
      %{
        id: 102,
        direction: "south",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 39,
        to_room_id: 38,
        inserted_at: ~U[2025-11-02 18:30:27Z],
        updated_at: ~U[2025-11-02 18:30:27Z]
      },
      %{
        id: 103,
        direction: "south",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 38,
        to_room_id: 40,
        inserted_at: ~U[2025-11-02 18:30:39Z],
        updated_at: ~U[2025-11-02 18:30:39Z]
      },
      %{
        id: 104,
        direction: "north",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 40,
        to_room_id: 38,
        inserted_at: ~U[2025-11-02 18:30:39Z],
        updated_at: ~U[2025-11-02 18:30:39Z]
      },
      %{
        id: 106,
        direction: "east",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 39,
        to_room_id: 41,
        inserted_at: ~U[2025-11-02 18:31:42Z],
        updated_at: ~U[2025-11-02 18:31:42Z]
      },
      %{
        id: 107,
        direction: "west",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 41,
        to_room_id: 39,
        inserted_at: ~U[2025-11-02 18:31:42Z],
        updated_at: ~U[2025-11-02 18:31:42Z]
      },
      %{
        id: 108,
        direction: "east",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 41,
        to_room_id: 42,
        inserted_at: ~U[2025-11-02 18:31:51Z],
        updated_at: ~U[2025-11-02 18:31:51Z]
      },
      %{
        id: 109,
        direction: "west",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 42,
        to_room_id: 41,
        inserted_at: ~U[2025-11-02 18:31:51Z],
        updated_at: ~U[2025-11-02 18:31:51Z]
      },
      %{
        id: 110,
        direction: "south",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 42,
        to_room_id: 43,
        inserted_at: ~U[2025-11-02 18:32:02Z],
        updated_at: ~U[2025-11-02 18:32:02Z]
      },
      %{
        id: 111,
        direction: "north",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 43,
        to_room_id: 42,
        inserted_at: ~U[2025-11-02 18:32:02Z],
        updated_at: ~U[2025-11-02 18:32:02Z]
      },
      %{
        id: 112,
        direction: "west",
        is_locked: true,
        key_required: "Freezer Key",
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 43,
        to_room_id: 45,
        inserted_at: ~U[2025-11-02 18:32:22Z],
        updated_at: ~U[2025-11-02 18:32:22Z]
      },
      %{
        id: 113,
        direction: "east",
        is_locked: true,
        key_required: "Freezer Key",
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 45,
        to_room_id: 43,
        inserted_at: ~U[2025-11-02 18:32:22Z],
        updated_at: ~U[2025-11-02 18:32:22Z]
      }
    ]

    Enum.each(doors_data, fn door_data ->
      execute("""
        INSERT INTO doors (id, name, description, direction, is_locked, key_required, door_type, properties, new_dungeon, from_room_id, to_room_id, inserted_at, updated_at)
        VALUES (#{door_data.id}, NULL, NULL, '#{door_data.direction}', #{door_data.is_locked}, #{if door_data.key_required, do: "'#{door_data.key_required}'", else: "NULL"}, '#{door_data.door_type}', '#{Jason.encode!(door_data.properties)}', #{door_data.new_dungeon}, #{door_data.from_room_id}, #{door_data.to_room_id}, '#{door_data.inserted_at}', '#{door_data.updated_at}')
      """)
    end)
  end

  def down do
    # Delete all the doors we inserted
    door_ids = [
      89,
      90,
      91,
      92,
      93,
      94,
      95,
      96,
      97,
      98,
      99,
      100,
      101,
      102,
      103,
      104,
      106,
      107,
      108,
      109,
      110,
      111,
      112,
      113
    ]

    Enum.each(door_ids, fn id ->
      execute("DELETE FROM doors WHERE id = #{id}")
    end)
  end
end

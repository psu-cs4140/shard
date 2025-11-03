defmodule Shard.Repo.Migrations.InsertDoorsData do
  use Ecto.Migration

  def up do
    # Insert door data
    doors_data = [
      %{
        id: 49,
        direction: "west",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 19,
        to_room_id: 20,
        inserted_at: ~U[2025-11-02 17:44:26Z],
        updated_at: ~U[2025-11-02 17:44:26Z]
      },
      %{
        id: 50,
        direction: "east",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 20,
        to_room_id: 19,
        inserted_at: ~U[2025-11-02 17:44:26Z],
        updated_at: ~U[2025-11-02 17:44:26Z]
      },
      %{
        id: 51,
        direction: "south",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 19,
        to_room_id: 22,
        inserted_at: ~U[2025-11-02 17:44:54Z],
        updated_at: ~U[2025-11-02 17:44:54Z]
      },
      %{
        id: 52,
        direction: "north",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 22,
        to_room_id: 19,
        inserted_at: ~U[2025-11-02 17:44:54Z],
        updated_at: ~U[2025-11-02 17:44:54Z]
      },
      %{
        id: 53,
        direction: "east",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 19,
        to_room_id: 24,
        inserted_at: ~U[2025-11-02 17:45:01Z],
        updated_at: ~U[2025-11-02 17:45:01Z]
      },
      %{
        id: 54,
        direction: "west",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 24,
        to_room_id: 19,
        inserted_at: ~U[2025-11-02 17:45:01Z],
        updated_at: ~U[2025-11-02 17:45:01Z]
      },
      %{
        id: 55,
        direction: "south",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 20,
        to_room_id: 21,
        inserted_at: ~U[2025-11-02 17:45:12Z],
        updated_at: ~U[2025-11-02 17:45:12Z]
      },
      %{
        id: 56,
        direction: "north",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 21,
        to_room_id: 20,
        inserted_at: ~U[2025-11-02 17:45:12Z],
        updated_at: ~U[2025-11-02 17:45:12Z]
      },
      %{
        id: 57,
        direction: "west",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 21,
        to_room_id: 22,
        inserted_at: ~U[2025-11-02 17:45:27Z],
        updated_at: ~U[2025-11-02 17:45:27Z]
      },
      %{
        id: 58,
        direction: "east",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 22,
        to_room_id: 21,
        inserted_at: ~U[2025-11-02 17:45:27Z],
        updated_at: ~U[2025-11-02 17:45:27Z]
      },
      %{
        id: 63,
        direction: "south",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 24,
        to_room_id: 25,
        inserted_at: ~U[2025-11-02 17:46:45Z],
        updated_at: ~U[2025-11-02 17:46:45Z]
      },
      %{
        id: 64,
        direction: "north",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 25,
        to_room_id: 24,
        inserted_at: ~U[2025-11-02 17:46:45Z],
        updated_at: ~U[2025-11-02 17:46:45Z]
      },
      %{
        id: 67,
        direction: "north",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 19,
        to_room_id: 23,
        inserted_at: ~U[2025-11-02 17:47:34Z],
        updated_at: ~U[2025-11-02 17:47:34Z]
      },
      %{
        id: 68,
        direction: "south",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 23,
        to_room_id: 19,
        inserted_at: ~U[2025-11-02 17:47:34Z],
        updated_at: ~U[2025-11-02 17:47:34Z]
      },
      %{
        id: 69,
        direction: "west",
        is_locked: true,
        key_required: "Sewer Key",
        door_type: "gate",
        properties: %{},
        new_dungeon: false,
        from_room_id: 20,
        to_room_id: 26,
        inserted_at: ~U[2025-11-02 17:48:17Z],
        updated_at: ~U[2025-11-02 17:48:17Z]
      },
      %{
        id: 70,
        direction: "east",
        is_locked: true,
        key_required: "Sewer Key",
        door_type: "gate",
        properties: %{},
        new_dungeon: false,
        from_room_id: 26,
        to_room_id: 20,
        inserted_at: ~U[2025-11-02 17:48:17Z],
        updated_at: ~U[2025-11-02 17:48:17Z]
      },
      %{
        id: 75,
        direction: "west",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 26,
        to_room_id: 27,
        inserted_at: ~U[2025-11-02 17:58:09Z],
        updated_at: ~U[2025-11-02 17:58:09Z]
      },
      %{
        id: 76,
        direction: "east",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 27,
        to_room_id: 26,
        inserted_at: ~U[2025-11-02 17:58:09Z],
        updated_at: ~U[2025-11-02 17:58:09Z]
      },
      %{
        id: 77,
        direction: "south",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 27,
        to_room_id: 28,
        inserted_at: ~U[2025-11-02 17:58:16Z],
        updated_at: ~U[2025-11-02 17:58:16Z]
      },
      %{
        id: 78,
        direction: "north",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 28,
        to_room_id: 27,
        inserted_at: ~U[2025-11-02 17:58:16Z],
        updated_at: ~U[2025-11-02 17:58:16Z]
      },
      %{
        id: 79,
        direction: "west",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 28,
        to_room_id: 29,
        inserted_at: ~U[2025-11-02 17:58:22Z],
        updated_at: ~U[2025-11-02 17:58:22Z]
      },
      %{
        id: 80,
        direction: "east",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 29,
        to_room_id: 28,
        inserted_at: ~U[2025-11-02 17:58:22Z],
        updated_at: ~U[2025-11-02 17:58:22Z]
      },
      %{
        id: 83,
        direction: "north",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 23,
        to_room_id: 31,
        inserted_at: ~U[2025-11-02 18:03:59Z],
        updated_at: ~U[2025-11-02 18:03:59Z]
      },
      %{
        id: 84,
        direction: "south",
        is_locked: true,
        key_required: "Manor Entrance Key",
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 31,
        to_room_id: 23,
        inserted_at: ~U[2025-11-02 18:03:59Z],
        updated_at: ~U[2025-11-02 18:15:15Z]
      },
      %{
        id: 85,
        direction: "north",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 31,
        to_room_id: 33,
        inserted_at: ~U[2025-11-02 18:04:07Z],
        updated_at: ~U[2025-11-02 18:04:07Z]
      },
      %{
        id: 86,
        direction: "south",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 33,
        to_room_id: 31,
        inserted_at: ~U[2025-11-02 18:04:07Z],
        updated_at: ~U[2025-11-02 18:04:07Z]
      },
      %{
        id: 87,
        direction: "north",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 33,
        to_room_id: 34,
        inserted_at: ~U[2025-11-02 18:05:30Z],
        updated_at: ~U[2025-11-02 18:05:30Z]
      },
      %{
        id: 88,
        direction: "south",
        is_locked: false,
        key_required: nil,
        door_type: "standard",
        properties: %{},
        new_dungeon: false,
        from_room_id: 34,
        to_room_id: 33,
        inserted_at: ~U[2025-11-02 18:05:30Z],
        updated_at: ~U[2025-11-02 18:05:30Z]
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
      49,
      50,
      51,
      52,
      53,
      54,
      55,
      56,
      57,
      58,
      63,
      64,
      67,
      68,
      69,
      70,
      75,
      76,
      77,
      78,
      79,
      80,
      83,
      84,
      85,
      86,
      87,
      88
    ]

    Enum.each(door_ids, fn id ->
      execute("DELETE FROM doors WHERE id = #{id}")
    end)
  end
end

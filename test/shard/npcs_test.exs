defmodule Shard.NpcsTest do
  use Shard.DataCase

  alias Shard.Npcs

  describe "Npcs context" do
    test "list_npcs returns all npcs" do
      npcs = Npcs.list_npcs()
      assert is_list(npcs)
    end

    test "get_npcs_by_room returns list" do
      npcs = Npcs.get_npcs_by_room(1)
      assert is_list(npcs)
    end

    test "get_npcs_by_location returns list" do
      npcs = Npcs.get_npcs_by_location(0, 0, 0)
      assert is_list(npcs)
    end

    test "get_npcs_by_type returns list" do
      npcs = Npcs.get_npcs_by_type("friendly")
      assert is_list(npcs)
    end

    test "get_npc_by_name returns npc or nil" do
      npc = Npcs.get_npc_by_name("Goldie")
      assert npc == nil or match?(%Shard.Npcs.Npc{}, npc)
    end

    test "list_rooms returns list" do
      rooms = Npcs.list_rooms()
      assert is_list(rooms)
    end
  end
end

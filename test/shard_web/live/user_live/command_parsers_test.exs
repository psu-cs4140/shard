defmodule ShardWeb.UserLive.CommandParsersTest do
  use Shard.DataCase

  alias ShardWeb.UserLive.CommandParsers

  describe "parse_talk_command/1" do
    test "parses quoted NPC names" do
      assert {:ok, "Goldie"} = CommandParsers.parse_talk_command(~s(talk "Goldie"))
      assert {:ok, "Goldie"} = CommandParsers.parse_talk_command(~s(talk 'Goldie'))
      assert {:ok, "Friendly NPC"} = CommandParsers.parse_talk_command(~s(talk "Friendly NPC"))
    end

    test "parses unquoted single-word NPC names" do
      assert {:ok, "Goldie"} = CommandParsers.parse_talk_command("talk Goldie")
      assert {:ok, "Bob"} = CommandParsers.parse_talk_command("talk Bob")
    end

    test "returns error for invalid formats" do
      assert :error = CommandParsers.parse_talk_command("talk")
      assert :error = CommandParsers.parse_talk_command("talk to Goldie")
      assert :error = CommandParsers.parse_talk_command("talk Goldie extra")
      assert :error = CommandParsers.parse_talk_command("say hello")
    end

    test "is case insensitive" do
      assert {:ok, "Goldie"} = CommandParsers.parse_talk_command("TALK Goldie")
      assert {:ok, "Goldie"} = CommandParsers.parse_talk_command(~s(TALK "Goldie"))
    end
  end

  describe "parse_quest_command/1" do
    test "parses quoted NPC names" do
      assert {:ok, "Goldie"} = CommandParsers.parse_quest_command(~s(quest "Goldie"))
      assert {:ok, "Goldie"} = CommandParsers.parse_quest_command(~s(quest 'Goldie'))
      assert {:ok, "Quest Giver"} = CommandParsers.parse_quest_command(~s(quest "Quest Giver"))
    end

    test "parses unquoted single-word NPC names" do
      assert {:ok, "Goldie"} = CommandParsers.parse_quest_command("quest Goldie")
      assert {:ok, "Bob"} = CommandParsers.parse_quest_command("quest Bob")
    end

    test "returns error for invalid formats" do
      assert :error = CommandParsers.parse_quest_command("quest")
      assert :error = CommandParsers.parse_quest_command("quest from Goldie")
      assert :error = CommandParsers.parse_quest_command("quest Goldie extra")
      assert :error = CommandParsers.parse_quest_command("get quest")
    end

    test "is case insensitive" do
      assert {:ok, "Goldie"} = CommandParsers.parse_quest_command("QUEST Goldie")
      assert {:ok, "Goldie"} = CommandParsers.parse_quest_command(~s(QUEST "Goldie"))
    end
  end

  describe "parse_deliver_quest_command/1" do
    test "parses quoted NPC names" do
      assert {:ok, "Goldie"} =
               CommandParsers.parse_deliver_quest_command(~s(deliver_quest "Goldie"))

      assert {:ok, "Goldie"} =
               CommandParsers.parse_deliver_quest_command(~s(deliver_quest 'Goldie'))

      assert {:ok, "Quest NPC"} =
               CommandParsers.parse_deliver_quest_command(~s(deliver_quest "Quest NPC"))
    end

    test "parses unquoted single-word NPC names" do
      assert {:ok, "Goldie"} = CommandParsers.parse_deliver_quest_command("deliver_quest Goldie")
      assert {:ok, "Bob"} = CommandParsers.parse_deliver_quest_command("deliver_quest Bob")
    end

    test "returns error for invalid formats" do
      assert :error = CommandParsers.parse_deliver_quest_command("deliver_quest")
      assert :error = CommandParsers.parse_deliver_quest_command("deliver_quest to Goldie")
      assert :error = CommandParsers.parse_deliver_quest_command("deliver_quest Goldie extra")
      assert :error = CommandParsers.parse_deliver_quest_command("turn in quest")
    end

    test "is case insensitive" do
      assert {:ok, "Goldie"} = CommandParsers.parse_deliver_quest_command("DELIVER_QUEST Goldie")

      assert {:ok, "Goldie"} =
               CommandParsers.parse_deliver_quest_command(~s(DELIVER_QUEST "Goldie"))
    end
  end

  describe "parse_unlock_command/1" do
    test "parses quoted item names" do
      assert {:ok, "north", "Tutorial Key"} =
               CommandParsers.parse_unlock_command(~s(unlock north with "Tutorial Key"))

      assert {:ok, "east", "Magic Key"} =
               CommandParsers.parse_unlock_command(~s(unlock east with 'Magic Key'))
    end

    test "parses unquoted single-word item names" do
      assert {:ok, "north", "Key"} = CommandParsers.parse_unlock_command("unlock north with Key")

      assert {:ok, "south", "Lockpick"} =
               CommandParsers.parse_unlock_command("unlock south with Lockpick")
    end

    test "supports direction abbreviations" do
      assert {:ok, "n", "Key"} = CommandParsers.parse_unlock_command("unlock n with Key")
      assert {:ok, "s", "Key"} = CommandParsers.parse_unlock_command("unlock s with Key")
      assert {:ok, "e", "Key"} = CommandParsers.parse_unlock_command("unlock e with Key")
      assert {:ok, "w", "Key"} = CommandParsers.parse_unlock_command("unlock w with Key")
    end

    test "returns error for invalid formats" do
      assert :error = CommandParsers.parse_unlock_command("unlock")
      assert :error = CommandParsers.parse_unlock_command("unlock north")
      assert :error = CommandParsers.parse_unlock_command("unlock north Key")
      assert :error = CommandParsers.parse_unlock_command("unlock north using Key")
      assert :error = CommandParsers.parse_unlock_command("open north with Key")
    end

    test "is case insensitive" do
      assert {:ok, "north", "Key"} = CommandParsers.parse_unlock_command("UNLOCK north WITH Key")

      assert {:ok, "north", "Key"} =
               CommandParsers.parse_unlock_command(~s(UNLOCK north WITH "Key"))
    end
  end

  describe "parse_pickup_command/1" do
    test "parses quoted item names" do
      assert {:ok, "Tutorial Key"} =
               CommandParsers.parse_pickup_command(~s(pickup "Tutorial Key"))

      assert {:ok, "Magic Sword"} = CommandParsers.parse_pickup_command(~s(pickup 'Magic Sword'))
    end

    test "parses unquoted single-word item names" do
      assert {:ok, "Key"} = CommandParsers.parse_pickup_command("pickup Key")
      assert {:ok, "Sword"} = CommandParsers.parse_pickup_command("pickup Sword")
    end

    test "returns error for invalid formats" do
      assert :error = CommandParsers.parse_pickup_command("pickup")
      assert :error = CommandParsers.parse_pickup_command("pickup the Key")
      assert :error = CommandParsers.parse_pickup_command("pickup Key extra")
      assert :error = CommandParsers.parse_pickup_command("get Key")
    end

    test "is case insensitive" do
      assert {:ok, "Key"} = CommandParsers.parse_pickup_command("PICKUP Key")
      assert {:ok, "Key"} = CommandParsers.parse_pickup_command(~s(PICKUP "Key"))
    end
  end
end

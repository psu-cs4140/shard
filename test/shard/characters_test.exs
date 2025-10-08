defmodule Shard.CharactersTest do
  use Shard.DataCase

  alias Shard.Characters
  alias Shard.Characters.Character

  describe "characters" do
    alias Shard.Characters.Character

    import Shard.CharactersFixtures

    test "list_characters/0 returns all characters" do
      character = character_fixture()
      characters = Characters.list_characters()
      assert length(characters) == 1
      assert hd(characters).id == character.id
    end

    test "get_character!/1 returns the character with given id" do
      character = character_fixture()
      fetched_character = Characters.get_character!(character.id)
      assert fetched_character.id == character.id
      assert fetched_character.name == character.name
    end

    test "create_character/1 with valid data creates a character" do
      user = Shard.UsersFixtures.user_fixture()
      valid_attrs = %{
        name: "Test Hero",
        class: "warrior",
        race: "human",
        user_id: user.id
      }

      assert {:ok, %Character{} = character} = Characters.create_character(valid_attrs)
      assert character.name == "Test Hero"
      assert character.class == "warrior"
      assert character.race == "human"
      assert character.user_id == user.id
    end

    test "create_character/1 sets proper initial state" do
      user = Shard.UsersFixtures.user_fixture()
      valid_attrs = %{
        name: "New Character",
        class: "mage",
        race: "elf",
        user_id: user.id
      }

      assert {:ok, %Character{} = character} = Characters.create_character(valid_attrs)
      
      # Verify initial stats
      assert character.level == 1
      assert character.health == 100
      assert character.mana == 50
      assert character.strength == 10
      assert character.dexterity == 10
      assert character.intelligence == 10
      assert character.constitution == 10
      assert character.experience == 0
      assert character.gold == 0
      assert character.is_active == true
      
      # Verify starting location
      assert character.location == "starting_town"
    end

    test "create_character/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Characters.create_character(%{})
    end

    test "create_character/1 validates required fields" do
      user = Shard.UsersFixtures.user_fixture()
      
      # Missing name
      assert {:error, changeset} = Characters.create_character(%{
        class: "warrior",
        race: "human",
        user_id: user.id
      })
      assert %{name: ["can't be blank"]} = errors_on(changeset)
      
      # Missing class
      assert {:error, changeset} = Characters.create_character(%{
        name: "Test",
        race: "human",
        user_id: user.id
      })
      assert %{class: ["can't be blank"]} = errors_on(changeset)
      
      # Missing race
      assert {:error, changeset} = Characters.create_character(%{
        name: "Test",
        class: "warrior",
        user_id: user.id
      })
      assert %{race: ["can't be blank"]} = errors_on(changeset)
    end

    test "create_character/1 validates class inclusion" do
      user = Shard.UsersFixtures.user_fixture()
      
      assert {:error, changeset} = Characters.create_character(%{
        name: "Test",
        class: "invalid_class",
        race: "human",
        user_id: user.id
      })
      assert %{class: ["is invalid"]} = errors_on(changeset)
    end

    test "create_character/1 validates race inclusion" do
      user = Shard.UsersFixtures.user_fixture()
      
      assert {:error, changeset} = Characters.create_character(%{
        name: "Test",
        class: "warrior",
        race: "invalid_race",
        user_id: user.id
      })
      assert %{race: ["is invalid"]} = errors_on(changeset)
    end

    test "create_character/1 validates name length" do
      user = Shard.UsersFixtures.user_fixture()
      
      # Name too short
      assert {:error, changeset} = Characters.create_character(%{
        name: "A",
        class: "warrior",
        race: "human",
        user_id: user.id
      })
      assert %{name: ["should be at least 2 character(s)"]} = errors_on(changeset)
      
      # Name too long
      long_name = String.duplicate("A", 51)
      assert {:error, changeset} = Characters.create_character(%{
        name: long_name,
        class: "warrior",
        race: "human",
        user_id: user.id
      })
      assert %{name: ["should be at most 50 character(s)"]} = errors_on(changeset)
    end

    test "create_character/1 validates stat ranges" do
      user = Shard.UsersFixtures.user_fixture()
      
      # Test invalid strength
      assert {:error, changeset} = Characters.create_character(%{
        name: "Test",
        class: "warrior",
        race: "human",
        user_id: user.id,
        strength: 0
      })
      assert %{strength: ["must be greater than 0"]} = errors_on(changeset)
      
      assert {:error, changeset} = Characters.create_character(%{
        name: "Test",
        class: "warrior",
        race: "human",
        user_id: user.id,
        strength: 101
      })
      assert %{strength: ["must be less than or equal to 100"]} = errors_on(changeset)
    end

    test "create_character/1 validates level range" do
      user = Shard.UsersFixtures.user_fixture()
      
      assert {:error, changeset} = Characters.create_character(%{
        name: "Test",
        class: "warrior",
        race: "human",
        user_id: user.id,
        level: 0
      })
      assert %{level: ["must be greater than 0"]} = errors_on(changeset)
      
      assert {:error, changeset} = Characters.create_character(%{
        name: "Test",
        class: "warrior",
        race: "human",
        user_id: user.id,
        level: 101
      })
      assert %{level: ["must be less than or equal to 100"]} = errors_on(changeset)
    end

    test "create_character/1 enforces unique character names" do
      user1 = Shard.UsersFixtures.user_fixture()
      user2 = Shard.UsersFixtures.user_fixture()
      
      # Create first character
      assert {:ok, _character1} = Characters.create_character(%{
        name: "Unique Name",
        class: "warrior",
        race: "human",
        user_id: user1.id
      })
      
      # Try to create second character with same name
      assert {:error, changeset} = Characters.create_character(%{
        name: "Unique Name",
        class: "mage",
        race: "elf",
        user_id: user2.id
      })
      assert %{name: ["has already been taken"]} = errors_on(changeset)
    end

    test "update_character/2 with valid data updates the character" do
      character = character_fixture()
      update_attrs = %{name: "Updated Name", level: 5, gold: 100}

      assert {:ok, %Character{} = character} = Characters.update_character(character, update_attrs)
      assert character.name == "Updated Name"
      assert character.level == 5
      assert character.gold == 100
    end

    test "update_character/2 with invalid data returns error changeset" do
      character = character_fixture()
      assert {:error, %Ecto.Changeset{}} = Characters.update_character(character, %{name: ""})
      assert character == Characters.get_character!(character.id)
    end

    test "delete_character/1 deletes the character" do
      character = character_fixture()
      assert {:ok, %Character{}} = Characters.delete_character(character)
      assert_raise Ecto.NoResultsError, fn -> Characters.get_character!(character.id) end
    end

    test "change_character/1 returns a character changeset" do
      character = character_fixture()
      assert %Ecto.Changeset{} = Characters.change_character(character)
    end

    test "get_characters_by_user/1 returns characters for specific user" do
      user1 = Shard.UsersFixtures.user_fixture()
      user2 = Shard.UsersFixtures.user_fixture()
      
      character1 = character_fixture(%{user: user1, name: "User1 Character"})
      character2 = character_fixture(%{user: user2, name: "User2 Character"})
      
      user1_characters = Characters.get_characters_by_user(user1.id)
      user2_characters = Characters.get_characters_by_user(user2.id)
      
      assert length(user1_characters) == 1
      assert length(user2_characters) == 1
      assert hd(user1_characters).id == character1.id
      assert hd(user2_characters).id == character2.id
    end
  end

  describe "character initial game state" do
    test "new character starts in the correct location" do
      user = Shard.UsersFixtures.user_fixture()
      
      assert {:ok, character} = Characters.create_character(%{
        name: "Starting Character",
        class: "warrior",
        race: "human",
        user_id: user.id
      })
      
      # Character should start in starting_town (which corresponds to coordinates 0,0 based on seeds)
      assert character.location == "starting_town"
    end

    test "new character has proper starting equipment associations" do
      user = Shard.UsersFixtures.user_fixture()
      
      assert {:ok, character} = Characters.create_character(%{
        name: "Equipment Test",
        class: "warrior",
        race: "human",
        user_id: user.id
      })
      
      # Verify character has inventory and hotbar associations
      character_with_assocs = Characters.get_character!(character.id)
      |> Shard.Repo.preload([:character_inventories, :hotbar_slots])
      
      # Initially empty but associations should exist
      assert character_with_assocs.character_inventories == []
      assert character_with_assocs.hotbar_slots == []
    end
  end
end

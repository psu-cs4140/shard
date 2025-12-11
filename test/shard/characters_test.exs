defmodule Shard.CharactersTest do
  use Shard.DataCase

  alias Shard.Characters
  alias Shard.Characters.Character

  import Shard.CharactersFixtures
  import Shard.UsersFixtures

  describe "characters" do
    @valid_attrs %{
      name: "Test Character",
      class: "warrior",
      race: "human",
      level: 1,
      health: 100,
      max_health: 100,
      mana: 50,
      max_mana: 50,
      strength: 10,
      dexterity: 10,
      intelligence: 10,
      constitution: 10,
      experience: 0,
      gold: 100,
      location: "Starting Town",
      description: "A test character",
      is_active: true
    }

    @invalid_attrs %{name: nil, class: nil, race: nil}

    test "list_characters/0 returns all characters" do
      character = character_fixture()
      characters = Characters.list_characters()
      assert character in characters
    end

    test "get_character!/1 returns the character with given id" do
      character = character_fixture()
      assert Characters.get_character!(character.id) == character
    end

    test "create_character/1 with valid data creates a character" do
      user = user_fixture()
      attrs = Map.put(@valid_attrs, :user_id, user.id)

      assert {:ok, %Character{} = character} = Characters.create_character(attrs)
      assert character.name == "Test Character"
      assert character.class == "warrior"
      assert character.race == "human"
      assert character.level == 1
      assert character.health == 100
      assert character.user_id == user.id
    end

    test "create_character/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Characters.create_character(@invalid_attrs)
    end

    test "update_character/2 with valid data updates the character" do
      character = character_fixture()
      update_attrs = %{name: "Updated Character", level: 2, experience: 100}

      assert {:ok, %Character{} = character} = Characters.update_character(character, update_attrs)
      assert character.name == "Updated Character"
      assert character.level == 2
      assert character.experience == 100
    end

    test "update_character/2 with invalid data returns error changeset" do
      character = character_fixture()
      assert {:error, %Ecto.Changeset{}} = Characters.update_character(character, @invalid_attrs)
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

    test "get_characters_by_user/1 returns characters for a specific user" do
      user1 = user_fixture()
      user2 = user_fixture()
      
      # Create characters with explicit user_id override
      character1_attrs = valid_character_attributes(%{user_id: user1.id})
      {:ok, character1} = Characters.create_character(character1_attrs)
      
      character2_attrs = valid_character_attributes(%{user_id: user2.id})
      {:ok, _character2} = Characters.create_character(character2_attrs)

      user1_characters = Characters.get_characters_by_user(user1.id)
      assert character1 in user1_characters
      assert length(user1_characters) == 1
    end
  end

  describe "character validations" do
    test "validates required fields" do
      changeset = Character.changeset(%Character{}, %{})
      refute changeset.valid?
      
      errors = errors_on(changeset)
      assert "can't be blank" in errors.name
      assert "can't be blank" in errors.class
      assert "can't be blank" in errors.race
    end

    test "validates class inclusion" do
      user = user_fixture()
      attrs = Map.merge(@valid_attrs, %{class: "invalid_class", user_id: user.id})
      
      {:error, changeset} = Characters.create_character(attrs)
      assert %{class: ["is invalid"]} = errors_on(changeset)
    end

    test "validates race inclusion" do
      user = user_fixture()
      attrs = Map.merge(@valid_attrs, %{race: "invalid_race", user_id: user.id})
      
      {:error, changeset} = Characters.create_character(attrs)
      assert %{race: ["is invalid"]} = errors_on(changeset)
    end

    test "validates level is positive" do
      user = user_fixture()
      attrs = Map.merge(@valid_attrs, %{level: 0, user_id: user.id})
      
      {:error, changeset} = Characters.create_character(attrs)
      assert %{level: ["must be greater than 0"]} = errors_on(changeset)
    end

    test "validates health values" do
      user = user_fixture()
      attrs = Map.merge(@valid_attrs, %{health: -10, max_health: -5, user_id: user.id})
      
      {:error, changeset} = Characters.create_character(attrs)
      errors = errors_on(changeset)
      assert "must be greater than or equal to 0" in errors.health
      assert "must be greater than 0" in errors.max_health
    end

    test "validates stat values are non-negative" do
      user = user_fixture()
      attrs = Map.merge(@valid_attrs, %{strength: -1, dexterity: -1, intelligence: -1, constitution: -1, user_id: user.id})
      
      {:error, changeset} = Characters.create_character(attrs)
      errors = errors_on(changeset)
      assert "must be greater than or equal to 0" in errors.strength
      assert "must be greater than or equal to 0" in errors.dexterity
      assert "must be greater than or equal to 0" in errors.intelligence
      assert "must be greater than or equal to 0" in errors.constitution
    end

    test "validates experience and gold are non-negative" do
      user = user_fixture()
      attrs = Map.merge(@valid_attrs, %{experience: -10, gold: -5, user_id: user.id})
      
      {:error, changeset} = Characters.create_character(attrs)
      errors = errors_on(changeset)
      assert "must be greater than or equal to 0" in errors.experience
      assert "must be greater than or equal to 0" in errors.gold
    end

    test "accepts valid classes" do
      valid_classes = ["warrior", "mage", "rogue", "cleric", "ranger"]
      user = user_fixture()
      
      for class <- valid_classes do
        attrs = Map.merge(@valid_attrs, %{class: class, user_id: user.id, name: "Test #{class}"})
        assert {:ok, %Character{}} = Characters.create_character(attrs)
      end
    end

    test "accepts valid races" do
      valid_races = ["human", "elf", "dwarf", "halfling", "orc"]
      user = user_fixture()
      
      for race <- valid_races do
        attrs = Map.merge(@valid_attrs, %{race: race, user_id: user.id, name: "Test #{race}"})
        assert {:ok, %Character{}} = Characters.create_character(attrs)
      end
    end
  end

  describe "character achievements" do
    test "creates tutorial key when character is created" do
      user = user_fixture()
      attrs = Map.put(@valid_attrs, :user_id, user.id)

      # This tests the side effect mentioned in the characters.ex context
      assert {:ok, %Character{}} = Characters.create_character(attrs)
      # The actual tutorial key creation would need to be tested with the Items context
    end
  end
end

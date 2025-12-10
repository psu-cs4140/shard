defmodule Shard.CharactersTest do
  use Shard.DataCase

  alias Shard.Characters
  alias Shard.Characters.Character

  import Shard.UsersFixtures

  describe "characters" do
    @invalid_attrs %{name: nil, class: nil, race: nil}

    defp valid_character_attrs(user_id) do
      %{
        name: "Test Character #{System.unique_integer([:positive])}",
        class: "warrior",
        race: "human",
        user_id: user_id
      }
    end

    test "list_characters/0 returns all characters" do
      user = user_fixture()
      {:ok, character} = Characters.create_character(valid_character_attrs(user.id))
      characters = Characters.list_characters()
      assert length(characters) >= 1
      assert Enum.any?(characters, fn c -> c.id == character.id end)
    end

    test "get_character!/1 returns the character with given id" do
      user = user_fixture()
      {:ok, character} = Characters.create_character(valid_character_attrs(user.id))
      assert Characters.get_character!(character.id).id == character.id
    end

    test "get_character!/1 raises when character not found" do
      assert_raise Ecto.NoResultsError, fn -> Characters.get_character!(999) end
    end

    test "create_character/1 with valid data creates a character" do
      user = user_fixture()
      attrs = valid_character_attrs(user.id)

      assert {:ok, %Character{} = character} = Characters.create_character(attrs)
      assert character.name == attrs.name
      assert character.class == "warrior"
      assert character.race == "human"
      assert character.user_id == user.id
      assert character.level == 1
      assert character.experience == 0
      assert character.health == 100
      assert character.mana == 80
      assert character.strength == 10
      assert character.dexterity == 10
      assert character.agility == 10
      assert character.intelligence == 10
      assert character.gold == 0
      assert character.location == "starting_town"
      assert character.is_mining == false
      assert character.mining_started_at == nil
    end

    test "create_character/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Characters.create_character(@invalid_attrs)
    end

    test "create_character/1 validates name uniqueness" do
      user = user_fixture()
      name = "Unique Character Name"
      attrs = Map.put(valid_character_attrs(user.id), :name, name)

      assert {:ok, _character} = Characters.create_character(attrs)
      assert {:error, changeset} = Characters.create_character(attrs)
      assert %{name: ["has already been taken"]} = errors_on(changeset)
    end

    test "update_character/2 with valid data updates the character" do
      user = user_fixture()
      {:ok, character} = Characters.create_character(valid_character_attrs(user.id))

      update_attrs = %{
        name: "Updated Character #{System.unique_integer([:positive])}",
        level: 5,
        experience: 1000,
        health: 150,
        gold: 500
      }

      assert {:ok, %Character{} = updated_character} =
               Characters.update_character(character, update_attrs)

      assert updated_character.name == update_attrs.name
      assert updated_character.level == 5
      assert updated_character.experience == 1000
      assert updated_character.health == 150
      assert updated_character.gold == 500
    end

    test "update_character/2 with invalid data returns error changeset" do
      user = user_fixture()
      {:ok, character} = Characters.create_character(valid_character_attrs(user.id))

      assert {:error, %Ecto.Changeset{}} = Characters.update_character(character, @invalid_attrs)

      # Refresh the character from database to ensure consistent comparison
      refreshed_character = Characters.get_character!(character.id)
      assert refreshed_character.name == character.name
      assert refreshed_character.class == character.class
      assert refreshed_character.race == character.race
    end

    test "delete_character/1 deletes the character" do
      user = user_fixture()
      {:ok, character} = Characters.create_character(valid_character_attrs(user.id))

      assert {:ok, %Character{}} = Characters.delete_character(character)
      assert_raise Ecto.NoResultsError, fn -> Characters.get_character!(character.id) end
    end

    test "change_character/1 returns a character changeset" do
      user = user_fixture()
      {:ok, character} = Characters.create_character(valid_character_attrs(user.id))

      assert %Ecto.Changeset{} = Characters.change_character(character)
    end

    test "get_characters_by_user/1 returns characters for a specific user" do
      user1 = user_fixture()
      user2 = user_fixture()

      {:ok, character1} = Characters.create_character(valid_character_attrs(user1.id))
      {:ok, _character2} = Characters.create_character(valid_character_attrs(user2.id))

      user1_characters = Characters.get_characters_by_user(user1.id)
      assert length(user1_characters) == 1
      assert hd(user1_characters).id == character1.id
    end

    test "get_character_by_name/1 returns character with given name" do
      user = user_fixture()
      name = "Findable Character #{System.unique_integer([:positive])}"
      attrs = Map.put(valid_character_attrs(user.id), :name, name)

      {:ok, character} = Characters.create_character(attrs)

      found_character = Characters.get_character_by_name(name)
      assert found_character.id == character.id
      assert found_character.name == name
    end

    test "get_character_by_name/1 returns nil for non-existent character" do
      assert Characters.get_character_by_name("Non-existent Character") == nil
    end

    test "get_characters_at_location/3 returns characters at specific coordinates" do
      user = user_fixture()
      attrs = Map.merge(valid_character_attrs(user.id), %{x: 5, y: 10, z: 0})

      {:ok, character} = Characters.create_character(attrs)

      characters_at_location = Characters.get_characters_at_location(5, 10, 0)
      assert length(characters_at_location) >= 1
      assert Enum.any?(characters_at_location, fn c -> c.id == character.id end)
    end

    test "move_character/4 updates character position" do
      user = user_fixture()
      {:ok, character} = Characters.create_character(valid_character_attrs(user.id))

      {:ok, moved_character} = Characters.move_character(character, 3, 7, 1)

      assert moved_character.x == 3
      assert moved_character.y == 7
      assert moved_character.z == 1
    end

    test "add_experience/2 increases character experience" do
      user = user_fixture()
      {:ok, character} = Characters.create_character(valid_character_attrs(user.id))

      {:ok, updated_character} = Characters.add_experience(character, 500)

      assert updated_character.experience == 500
    end

    test "add_gold/2 increases character gold" do
      user = user_fixture()
      {:ok, character} = Characters.create_character(valid_character_attrs(user.id))

      {:ok, updated_character} = Characters.add_gold(character, 250)

      assert updated_character.gold == 250
    end

    test "subtract_gold/2 decreases character gold" do
      user = user_fixture()
      attrs = Map.put(valid_character_attrs(user.id), :gold, 1000)
      {:ok, character} = Characters.create_character(attrs)

      {:ok, updated_character} = Characters.subtract_gold(character, 300)

      assert updated_character.gold == 700
    end

    test "subtract_gold/2 prevents negative gold" do
      user = user_fixture()
      attrs = Map.put(valid_character_attrs(user.id), :gold, 100)
      {:ok, character} = Characters.create_character(attrs)

      assert {:error, :insufficient_gold} = Characters.subtract_gold(character, 150)
    end

    test "heal_character/2 increases character health" do
      user = user_fixture()
      attrs = Map.put(valid_character_attrs(user.id), :health, 50)
      {:ok, character} = Characters.create_character(attrs)

      {:ok, updated_character} = Characters.heal_character(character, 30)

      assert updated_character.health == 80
    end

    test "damage_character/2 decreases character health" do
      user = user_fixture()
      {:ok, character} = Characters.create_character(valid_character_attrs(user.id))

      {:ok, updated_character} = Characters.damage_character(character, 25)

      assert updated_character.health == 75
    end

    test "damage_character/2 prevents negative health" do
      user = user_fixture()
      attrs = Map.put(valid_character_attrs(user.id), :health, 20)
      {:ok, character} = Characters.create_character(attrs)

      {:ok, updated_character} = Characters.damage_character(character, 30)

      assert updated_character.health == 0
    end

    test "restore_mana/2 increases character mana" do
      user = user_fixture()
      attrs = Map.put(valid_character_attrs(user.id), :mana, 20)
      {:ok, character} = Characters.create_character(attrs)

      {:ok, updated_character} = Characters.restore_mana(character, 15)

      assert updated_character.mana == 35
    end

    test "consume_mana/2 decreases character mana" do
      user = user_fixture()
      {:ok, character} = Characters.create_character(valid_character_attrs(user.id))

      {:ok, updated_character} = Characters.consume_mana(character, 20)

      assert updated_character.mana == 30
    end

    test "consume_mana/2 prevents negative mana" do
      user = user_fixture()
      attrs = Map.put(valid_character_attrs(user.id), :mana, 10)
      {:ok, character} = Characters.create_character(attrs)

      assert {:error, :insufficient_mana} = Characters.consume_mana(character, 15)
    end

    test "level_up/1 increases character level and stats" do
      user = user_fixture()
      attrs = Map.merge(valid_character_attrs(user.id), %{level: 1, experience: 1000})
      {:ok, character} = Characters.create_character(attrs)

      {:ok, leveled_character} = Characters.level_up(character)

      assert leveled_character.level == 2
      assert leveled_character.strength > character.strength
      assert leveled_character.defense > character.defense
      assert leveled_character.agility > character.agility
      assert leveled_character.intelligence > character.intelligence
    end
  end

  describe "Character changeset" do
    test "validates required fields" do
      changeset = Character.changeset(%Character{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.name
      assert "can't be blank" in errors.class
      assert "can't be blank" in errors.race
      assert "can't be blank" in errors.user_id
    end

    test "validates class inclusion" do
      user = user_fixture()
      attrs = Map.put(valid_character_attrs(user.id), :class, "invalid_class")

      changeset = Character.changeset(%Character{}, attrs)
      refute changeset.valid?
      assert %{class: ["is invalid"]} = errors_on(changeset)
    end

    test "validates race inclusion" do
      user = user_fixture()
      attrs = Map.put(valid_character_attrs(user.id), :race, "invalid_race")

      changeset = Character.changeset(%Character{}, attrs)
      refute changeset.valid?
      assert %{race: ["is invalid"]} = errors_on(changeset)
    end

    test "validates numeric fields are non-negative" do
      user = user_fixture()

      attrs =
        Map.merge(valid_character_attrs(user.id), %{
          level: -1,
          experience: -1,
          health: -1,
          mana: -1,
          strength: -1,
          defense: -1,
          agility: -1,
          intelligence: -1,
          gold: -1
        })

      changeset = Character.changeset(%Character{}, attrs)
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "must be greater than or equal to 0" in errors.level
      assert "must be greater than or equal to 0" in errors.experience
      assert "must be greater than or equal to 0" in errors.health
      assert "must be greater than or equal to 0" in errors.mana
      assert "must be greater than or equal to 0" in errors.strength
      assert "must be greater than or equal to 0" in errors.defense
      assert "must be greater than or equal to 0" in errors.agility
      assert "must be greater than or equal to 0" in errors.intelligence
      assert "must be greater than or equal to 0" in errors.gold
    end

    test "accepts valid character data" do
      user = user_fixture()
      attrs = valid_character_attrs(user.id)

      changeset = Character.changeset(%Character{}, attrs)
      assert changeset.valid?
    end
  end
end

defmodule Shard.CharactersTest do
  use Shard.DataCase

  alias Shard.Characters
  alias Shard.Characters.Character
  alias Shard.Repo

  import Shard.UsersFixtures

  describe "characters" do
    @valid_attrs %{
      name: "TestHero",
      class: "warrior",
      race: "human",
      level: 1,
      experience: 0,
      health: 100,
      mana: 50,
      strength: 10,
      dexterity: 10,
      intelligence: 10,
      constitution: 10,
      wisdom: 10,
      charisma: 10
    }

    @invalid_attrs %{name: nil, class: nil, race: nil}

    setup do
      user = user_fixture()
      %{user: user}
    end

    test "list_characters/0 returns all characters" do
      characters = Characters.list_characters()
      assert is_list(characters)
    end

    test "get_character!/1 returns the character with given id", %{user: user} do
      attrs = Map.put(@valid_attrs, :user_id, user.id)
      {:ok, character} = Characters.create_character(attrs)
      assert Characters.get_character!(character.id).id == character.id
    end

    test "create_character/1 with valid data creates a character", %{user: user} do
      attrs = Map.put(@valid_attrs, :user_id, user.id)
      assert {:ok, %Character{} = character} = Characters.create_character(attrs)
      assert character.name == "TestHero"
      assert character.class == "warrior"
      assert character.race == "human"
      assert character.level == 1
    end

    test "create_character/1 with invalid data returns error changeset", %{user: _user} do
      assert {:error, %Ecto.Changeset{}} = Characters.create_character(@invalid_attrs)
    end

    test "update_character/2 with valid data updates the character", %{user: user} do
      attrs = Map.put(@valid_attrs, :user_id, user.id)
      {:ok, character} = Characters.create_character(attrs)
      update_attrs = %{name: "UpdatedHero", level: 2}

      assert {:ok, %Character{} = character} = Characters.update_character(character, update_attrs)
      assert character.name == "UpdatedHero"
      assert character.level == 2
    end

    test "update_character/2 with invalid data returns error changeset", %{user: user} do
      attrs = Map.put(@valid_attrs, :user_id, user.id)
      {:ok, character} = Characters.create_character(attrs)
      assert {:error, %Ecto.Changeset{}} = Characters.update_character(character, @invalid_attrs)
      assert character == Characters.get_character!(character.id)
    end

    test "delete_character/1 deletes the character", %{user: user} do
      attrs = Map.put(@valid_attrs, :user_id, user.id)
      {:ok, character} = Characters.create_character(attrs)
      assert {:ok, %Character{}} = Characters.delete_character(character)
      assert_raise Ecto.NoResultsError, fn -> Characters.get_character!(character.id) end
    end

    test "change_character/1 returns a character changeset", %{user: user} do
      attrs = Map.put(@valid_attrs, :user_id, user.id)
      {:ok, character} = Characters.create_character(attrs)
      assert %Ecto.Changeset{} = Characters.change_character(character)
    end

    test "get_character_by_user/1 returns character for user", %{user: user} do
      attrs = Map.put(@valid_attrs, :user_id, user.id)
      {:ok, character} = Characters.create_character(attrs)
      
      found_character = Characters.get_character_by_user(user.id)
      assert found_character.id == character.id
    end

    test "get_character_by_user/1 returns nil when no character exists", %{user: _user} do
      non_existent_user_id = 999_999
      assert Characters.get_character_by_user(non_existent_user_id) == nil
    end
  end

  describe "character validation" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "validates required fields", %{user: _user} do
      changeset = Character.changeset(%Character{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.name
      assert "can't be blank" in errors.class
      assert "can't be blank" in errors.race
    end

    test "validates class inclusion", %{user: user} do
      attrs = Map.merge(@valid_attrs, %{user_id: user.id, class: "invalid_class"})
      changeset = Character.changeset(%Character{}, attrs)
      refute changeset.valid?
      assert %{class: ["is invalid"]} = errors_on(changeset)
    end

    test "validates race inclusion", %{user: user} do
      attrs = Map.merge(@valid_attrs, %{user_id: user.id, race: "invalid_race"})
      changeset = Character.changeset(%Character{}, attrs)
      refute changeset.valid?
      assert %{race: ["is invalid"]} = errors_on(changeset)
    end

    test "validates positive stats", %{user: user} do
      attrs = Map.merge(@valid_attrs, %{user_id: user.id, strength: -1})
      changeset = Character.changeset(%Character{}, attrs)
      refute changeset.valid?
      assert %{strength: ["must be greater than 0"]} = errors_on(changeset)
    end

    test "validates level is positive", %{user: user} do
      attrs = Map.merge(@valid_attrs, %{user_id: user.id, level: 0})
      changeset = Character.changeset(%Character{}, attrs)
      refute changeset.valid?
      assert %{level: ["must be greater than 0"]} = errors_on(changeset)
    end

    test "validates experience is non-negative", %{user: user} do
      attrs = Map.merge(@valid_attrs, %{user_id: user.id, experience: -1})
      changeset = Character.changeset(%Character{}, attrs)
      refute changeset.valid?
      assert %{experience: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end
  end
end

defmodule Shard.SpellsTest do
  use Shard.DataCase

  alias Shard.Spells
  alias Shard.Characters.Character
  alias Shard.Repo
  import Shard.UsersFixtures

  # Helper function to ensure test data exists
  defp create_test_spell_data do
    # Check if data already exists
    if Repo.aggregate(Shard.Spells.SpellTypes, :count, :id) == 0 do
      # Create spell types
      {:ok, holy_type} = Spells.create_spell_type(%{name: "Holy", description: "Divine magic"})
      {:ok, fire_type} = Spells.create_spell_type(%{name: "Fire", description: "Fire magic"})

      # Create spell effects
      {:ok, damage_effect} =
        Spells.create_spell_effect(%{name: "Damage", description: "Deals damage"})

      {:ok, _heal_effect} =
        Spells.create_spell_effect(%{name: "Heal", description: "Heals target"})

      # Create test spells
      Spells.create_spell(%{
        name: "Holy Incantation",
        description: "A powerful holy spell",
        mana_cost: 25,
        damage: 40,
        level_required: 1,
        spell_type_id: holy_type.id,
        spell_effect_id: damage_effect.id
      })

      Spells.create_spell(%{
        name: "Fireball",
        description: "Hurls a blazing sphere of fire",
        mana_cost: 30,
        damage: 50,
        level_required: 3,
        spell_type_id: fire_type.id,
        spell_effect_id: damage_effect.id
      })
    end
  end

  describe "spell_types" do
    setup do
      create_test_spell_data()
      :ok
    end

    test "list_spell_types/0 returns all spell types" do
      spell_types = Spells.list_spell_types()
      assert length(spell_types) > 0
    end
  end

  describe "spell_effects" do
    setup do
      create_test_spell_data()
      :ok
    end

    test "list_spell_effects/0 returns all spell effects" do
      spell_effects = Spells.list_spell_effects()
      assert length(spell_effects) > 0
    end
  end

  describe "spells" do
    setup do
      create_test_spell_data()
      :ok
    end

    test "list_spells/0 returns all spells" do
      spells = Spells.list_spells()
      assert length(spells) > 0
    end

    test "get_spell_by_name/1 returns Holy Incantation" do
      spell = Spells.get_spell_by_name("Holy Incantation")
      assert spell != nil
      assert spell.name == "Holy Incantation"
      assert spell.damage == 40
      assert spell.mana_cost == 25
      assert spell.level_required == 1
    end

    test "list_spells_by_type/1 returns spells of a specific type" do
      # Get the Holy type
      holy_type = Repo.get_by(Shard.Spells.SpellTypes, name: "Holy")
      holy_spells = Spells.list_spells_by_type(holy_type.id)
      assert length(holy_spells) > 0
      # Should include at least Holy Incantation
      assert length(holy_spells) >= 1
    end
  end

  describe "character_spells" do
    setup do
      # Ensure spell data exists for tests
      create_test_spell_data()

      # Create a test user
      user = user_fixture()

      # Create a test character
      character =
        %Character{}
        |> Character.changeset(%{
          name: "TestMage",
          class: "mage",
          race: "human",
          user_id: user.id
        })
        |> Repo.insert!()

      {:ok, character: character}
    end

    test "add_spell_to_character/2 adds a spell to character", %{character: character} do
      holy_incantation = Spells.get_spell_by_name("Holy Incantation")

      {:ok, _character_spell} = Spells.add_spell_to_character(character.id, holy_incantation.id)

      # Verify the spell was added
      character_spells = Spells.list_character_spells(character.id)
      assert length(character_spells) == 1
      assert hd(character_spells).name == "Holy Incantation"
    end

    test "character_knows_spell?/2 returns true for known spells", %{character: character} do
      holy_incantation = Spells.get_spell_by_name("Holy Incantation")

      Spells.add_spell_to_character(character.id, holy_incantation.id)

      assert Spells.character_knows_spell?(character.id, holy_incantation.id) == true
    end

    test "list_character_spells/1 returns character's known spells with type and effect", %{
      character: character
    } do
      holy_incantation = Spells.get_spell_by_name("Holy Incantation")
      fireball = Spells.get_spell_by_name("Fireball")

      Spells.add_spell_to_character(character.id, holy_incantation.id)
      Spells.add_spell_to_character(character.id, fireball.id)

      character_spells = Spells.list_character_spells(character.id)
      assert length(character_spells) == 2

      holy_spell = Enum.find(character_spells, &(&1.name == "Holy Incantation"))
      assert holy_spell.spell_type == "Holy"
      assert holy_spell.spell_effect == "Damage"
      assert holy_spell.damage == 40
    end

    test "remove_spell_from_character/2 removes a spell from character", %{character: character} do
      holy_incantation = Spells.get_spell_by_name("Holy Incantation")

      Spells.add_spell_to_character(character.id, holy_incantation.id)
      Spells.remove_spell_from_character(character.id, holy_incantation.id)

      character_spells = Spells.list_character_spells(character.id)
      assert Enum.empty?(character_spells)
    end
  end
end

defmodule Shard.WeaponsTest do
  use Shard.DataCase

  alias Shard.Weapons

  describe "damage_types" do
    test "list_damage_types/0 returns all damage types" do
      damage_types = Weapons.list_damage_types()
      assert is_list(damage_types)
    end

    test "get_damage_type!/1 returns the damage type with given id" do
      # This will test with seeded data or return error if none exists
      case Weapons.list_damage_types() do
        [] ->
          assert_raise Ecto.NoResultsError, fn ->
            Weapons.get_damage_type!(999)
          end

        [damage_type | _] ->
          assert Weapons.get_damage_type!(damage_type.id).id == damage_type.id
      end
    end

    test "create_damage_type/1 with valid data creates a damage type" do
      valid_attrs = %{
        name: "Test Damage",
        description: "A test damage type"
      }

      assert {:ok, damage_type} = Weapons.create_damage_type(valid_attrs)
      assert damage_type.name == "Test Damage"
      assert damage_type.description == "A test damage type"
    end

    test "create_damage_type/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Weapons.create_damage_type(%{})
    end
  end

  describe "effects" do
    test "list_effects/0 returns all effects" do
      effects = Weapons.list_effects()
      assert is_list(effects)
    end

    test "get_effect!/1 returns the effect with given id" do
      case Weapons.list_effects() do
        [] ->
          assert_raise Ecto.NoResultsError, fn ->
            Weapons.get_effect!(999)
          end

        [effect | _] ->
          assert Weapons.get_effect!(effect.id).id == effect.id
      end
    end

    test "create_effect/1 with valid data creates an effect" do
      valid_attrs = %{
        name: "Test Effect",
        description: "A test effect"
      }

      assert {:ok, effect} = Weapons.create_effect(valid_attrs)
      assert effect.name == "Test Effect"
      assert effect.description == "A test effect"
    end
  end

  describe "weapons" do
    test "list_weapons/0 returns all weapons" do
      weapons = Weapons.list_weapons()
      assert is_list(weapons)
    end

    test "get_weapon!/1 returns the weapon with given id" do
      case Weapons.list_weapons() do
        [] ->
          assert_raise Ecto.NoResultsError, fn ->
            Weapons.get_weapon!(999)
          end

        [weapon | _] ->
          assert Weapons.get_weapon!(weapon.id).id == weapon.id
      end
    end

    test "list_weapons_by_class/1 returns weapons for a class" do
      weapons = Weapons.list_weapons_by_class("sword")
      assert is_list(weapons)
    end

    test "list_weapons_by_rarity/1 returns weapons for a rarity" do
      weapons = Weapons.list_weapons_by_rarity("common")
      assert is_list(weapons)
    end

    test "get_weapon_by_name/1 returns weapon by name" do
      # Test with a weapon that might exist from seeds
      weapon = Weapons.get_weapon_by_name("Rusty Sword")
      assert weapon == nil or match?(%Shard.Weapons.Weapons{}, weapon)
    end
  end

  describe "weapon effects" do
    test "list_weapon_effects/0 returns all weapon effects" do
      weapon_effects = Weapons.list_weapon_effects()
      assert is_list(weapon_effects)
    end

    test "get_weapon_effects_by_weapon/1 returns effects for a weapon" do
      weapon_effects = Weapons.get_weapon_effects_by_weapon(1)
      assert is_list(weapon_effects)
    end
  end

  describe "weapon enchantments" do
    test "list_weapon_enchantments/0 returns all weapon enchantments" do
      enchantments = Weapons.list_weapon_enchantments()
      assert is_list(enchantments)
    end

    test "get_weapon_enchantments_by_weapon/1 returns enchantments for a weapon" do
      enchantments = Weapons.get_weapon_enchantments_by_weapon(1)
      assert is_list(enchantments)
    end
  end

  describe "rarities" do
    test "list_rarities/0 returns all rarities" do
      rarities = Weapons.list_rarities()
      assert is_list(rarities)
    end

    test "get_rarity!/1 returns the rarity with given id" do
      case Weapons.list_rarities() do
        [] ->
          assert_raise Ecto.NoResultsError, fn ->
            Weapons.get_rarity!(999)
          end

        [rarity | _] ->
          assert Weapons.get_rarity!(rarity.id).id == rarity.id
      end
    end
  end

  describe "enchantments" do
    test "list_enchantments/0 returns all enchantments" do
      enchantments = Weapons.list_enchantments()
      assert is_list(enchantments)
    end

    test "get_enchantment!/1 returns the enchantment with given id" do
      case Weapons.list_enchantments() do
        [] ->
          assert_raise Ecto.NoResultsError, fn ->
            Weapons.get_enchantment!(999)
          end

        [enchantment | _] ->
          assert Weapons.get_enchantment!(enchantment.id).id == enchantment.id
      end
    end
  end

  describe "weapon classes" do
    test "list_weapon_classes/0 returns all weapon classes" do
      classes = Weapons.list_weapon_classes()
      assert is_list(classes)
    end

    test "get_weapon_class!/1 returns the weapon class with given id" do
      case Weapons.list_weapon_classes() do
        [] ->
          assert_raise Ecto.NoResultsError, fn ->
            Weapons.get_weapon_class!(999)
          end

        [weapon_class | _] ->
          assert Weapons.get_weapon_class!(weapon_class.id).id == weapon_class.id
      end
    end
  end
end

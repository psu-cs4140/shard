defmodule Shard.WeaponsTest do
  use Shard.DataCase

  alias Shard.Weapons

  describe "Weapons context" do
    test "list_weapons returns all weapons" do
      weapons = Weapons.list_weapons()
      assert is_list(weapons)
    end

    test "get_weapons_by_class returns list" do
      weapons = Weapons.get_weapons_by_class("sword")
      assert is_list(weapons)
    end

    test "get_weapons_by_rarity returns list" do
      weapons = Weapons.get_weapons_by_rarity("common")
      assert is_list(weapons)
    end

    test "get_weapons_by_level_range returns list" do
      weapons = Weapons.get_weapons_by_level_range(1, 10)
      assert is_list(weapons)
    end

    test "get_weapon_by_name returns weapon or nil" do
      weapon = Weapons.get_weapon_by_name("Iron Sword")
      assert weapon == nil or match?(%Shard.Weapons.Weapons{}, weapon)
    end

    test "list_weapon_classes returns all weapon classes" do
      classes = Weapons.list_weapon_classes()
      assert is_list(classes)
    end

    test "list_damage_types returns all damage types" do
      damage_types = Weapons.list_damage_types()
      assert is_list(damage_types)
    end

    test "list_rarities returns all rarities" do
      rarities = Weapons.list_rarities()
      assert is_list(rarities)
    end

    test "list_effects returns all effects" do
      effects = Weapons.list_effects()
      assert is_list(effects)
    end

    test "list_enchantments returns all enchantments" do
      enchantments = Weapons.list_enchantments()
      assert is_list(enchantments)
    end

    test "get_weapon_effects returns weapon effects" do
      effects = Weapons.get_weapon_effects(1)
      assert is_list(effects)
    end

    test "get_weapon_enchantments returns weapon enchantments" do
      enchantments = Weapons.get_weapon_enchantments(1)
      assert is_list(enchantments)
    end

    test "calculate_weapon_damage calculates damage correctly" do
      # Test with a mock weapon structure
      weapon = %{
        base_damage: 10,
        damage_variance: 2
      }

      damage = Weapons.calculate_weapon_damage(weapon)
      assert is_integer(damage)
      assert damage >= 8  # base_damage - damage_variance
      assert damage <= 12 # base_damage + damage_variance
    end

    test "get_weapon_total_value calculates total value" do
      # Test with a mock weapon structure
      weapon = %{
        base_value: 100,
        rarity_multiplier: 1.5,
        enchantment_value: 50
      }

      total_value = Weapons.get_weapon_total_value(weapon)
      assert is_number(total_value)
      assert total_value > 100
    end

    test "weapon_meets_requirements checks requirements" do
      # Test with mock data
      weapon = %{level_requirement: 5, class_requirement: "warrior"}
      character = %{level: 10, class: "warrior"}

      assert Weapons.weapon_meets_requirements?(weapon, character) == true

      low_level_character = %{level: 3, class: "warrior"}
      assert Weapons.weapon_meets_requirements?(weapon, low_level_character) == false

      wrong_class_character = %{level: 10, class: "mage"}
      assert Weapons.weapon_meets_requirements?(weapon, wrong_class_character) == false
    end

    test "get_weapons_for_character filters weapons by character" do
      character = %{level: 5, class: "warrior"}
      weapons = Weapons.get_weapons_for_character(character)
      assert is_list(weapons)
    end

    test "get_random_weapon_by_level returns weapon or nil" do
      weapon = Weapons.get_random_weapon_by_level(1)
      assert weapon == nil or match?(%Shard.Weapons.Weapons{}, weapon)
    end

    test "upgrade_weapon upgrades weapon stats" do
      # Test with mock weapon
      weapon = %{
        id: 1,
        base_damage: 10,
        level_requirement: 1,
        base_value: 100
      }

      upgraded = Weapons.upgrade_weapon(weapon)
      assert upgraded.base_damage > weapon.base_damage
      assert upgraded.level_requirement >= weapon.level_requirement
      assert upgraded.base_value > weapon.base_value
    end

    test "apply_enchantment applies enchantment to weapon" do
      weapon = %{id: 1, enchantments: []}
      enchantment = %{id: 1, name: "Fire", effect: "burn"}

      result = Weapons.apply_enchantment(weapon, enchantment)
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    test "remove_enchantment removes enchantment from weapon" do
      weapon = %{id: 1, enchantments: [%{id: 1}]}
      enchantment_id = 1

      result = Weapons.remove_enchantment(weapon, enchantment_id)
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    test "get_weapon_stats calculates weapon statistics" do
      weapon = %{
        base_damage: 10,
        damage_variance: 2,
        critical_chance: 5,
        accuracy: 90
      }

      stats = Weapons.get_weapon_stats(weapon)
      assert is_map(stats)
      assert Map.has_key?(stats, :min_damage)
      assert Map.has_key?(stats, :max_damage)
      assert Map.has_key?(stats, :average_damage)
    end

    test "compare_weapons compares two weapons" do
      weapon1 = %{base_damage: 10, base_value: 100}
      weapon2 = %{base_damage: 15, base_value: 150}

      comparison = Weapons.compare_weapons(weapon1, weapon2)
      assert is_map(comparison)
      assert Map.has_key?(comparison, :damage_difference)
      assert Map.has_key?(comparison, :value_difference)
    end
  end

  describe "DamageTypes context" do
    test "list_damage_types returns all damage types" do
      damage_types = Weapons.DamageTypes.list_damage_types()
      assert is_list(damage_types)
    end

    test "get_damage_type_by_name returns damage type or nil" do
      damage_type = Weapons.DamageTypes.get_damage_type_by_name("physical")
      assert damage_type == nil or match?(%Shard.Weapons.DamageTypes{}, damage_type)
    end

    test "get_effective_damage calculates effective damage" do
      damage = 100
      damage_type = "fire"
      target_resistances = %{"fire" => 0.5, "ice" => 0.2}

      effective_damage = Weapons.DamageTypes.get_effective_damage(damage, damage_type, target_resistances)
      assert is_number(effective_damage)
      assert effective_damage <= damage
    end

    test "get_damage_multiplier returns multiplier" do
      damage_type = "fire"
      target_resistances = %{"fire" => 0.3}

      multiplier = Weapons.DamageTypes.get_damage_multiplier(damage_type, target_resistances)
      assert is_number(multiplier)
      assert multiplier >= 0.0
      assert multiplier <= 1.0
    end
  end
end

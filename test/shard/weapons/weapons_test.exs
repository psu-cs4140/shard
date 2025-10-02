defmodule Shard.Weapons.WeaponsTest do
  use Shard.DataCase

  alias Shard.Weapons.Weapons

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      attrs = %{
        name: "Test Weapon",
        damage: 10,
        gold_value: 100,
        description: "A test weapon"
      }

      changeset = Weapons.changeset(%Weapons{}, attrs)
      assert changeset.valid?
    end

    test "invalid changeset when missing required fields" do
      attrs = %{}

      changeset = Weapons.changeset(%Weapons{}, attrs)
      refute changeset.valid?
      assert errors_on(changeset) == %{
               name: ["can't be blank"],
               damage: ["can't be blank"],
               gold_value: ["can't be blank"],
               description: ["can't be blank"]
             }
    end

    test "valid changeset with optional fields" do
      attrs = %{
        name: "Test Weapon",
        damage: 10,
        gold_value: 100,
        description: "A test weapon",
        weapon_class_id: 1,
        rarity_id: 1
      }

      changeset = Weapons.changeset(%Weapons{}, attrs)
      assert changeset.valid?
    end
  end

  describe "schema" do
    test "has the correct fields" do
      weapon = %Weapons{
        name: "Test Weapon",
        damage: 10,
        gold_value: 100,
        description: "A test weapon",
        weapon_class_id: 1,
        rarity_id: 1
      }

      assert weapon.name == "Test Weapon"
      assert weapon.damage == 10
      assert weapon.gold_value == 100
      assert weapon.description == "A test weapon"
      assert weapon.weapon_class_id == 1
      assert weapon.rarity_id == 1
    end
  end
end

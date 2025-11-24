defmodule Shard.SpellScrollsTest do
  use Shard.DataCase

  alias Shard.{Items, Spells, Repo}
  alias Shard.Items.{Item, RoomItem}
  alias Shard.Characters.Character

  describe "spell scrolls" do
    setup do
      # Create spell types and effects first
      {:ok, holy_type} = Spells.create_spell_type(%{name: "Holy", description: "Holy magic"})

      {:ok, damage_effect} =
        Spells.create_spell_effect(%{name: "Damage", description: "Deals damage"})

      # Create a spell
      {:ok, spell} =
        Spells.create_spell(%{
          name: "Test Spell",
          description: "A test spell",
          mana_cost: 10,
          damage: 20,
          level_required: 1,
          spell_type_id: holy_type.id,
          spell_effect_id: damage_effect.id
        })

      # Create a spell scroll item
      {:ok, scroll} =
        Items.create_item(%{
          name: "Scroll of Test Spell",
          description: "Learn Test Spell by picking up this scroll",
          item_type: "consumable",
          rarity: "common",
          value: 50,
          spell_id: spell.id,
          pickup: true,
          usable: true
        })

      # Create a character
      character =
        %Character{
          name: "Test Character",
          class: "warrior",
          race: "human",
          level: 1,
          health: 100,
          mana: 50,
          experience: 0,
          location: "0,0,0"
        }
        |> Repo.insert!()

      %{spell: spell, scroll: scroll, character: character}
    end

    test "using a spell scroll teaches the spell to the character", %{
      spell: spell,
      scroll: scroll,
      character: character
    } do
      # Place the scroll in a room
      {:ok, room_item} =
        %RoomItem{}
        |> RoomItem.changeset(%{
          location: "0,0,0",
          item_id: scroll.id,
          quantity: 1
        })
        |> Repo.insert()

      # Character should not know the spell initially
      refute Spells.character_knows_spell?(character.id, spell.id)

      # Pick up the scroll
      {:ok, :picked_up} = Items.pick_up_item(character.id, room_item.id)

      # Character should NOT know the spell yet (not auto-learned on pickup)
      refute Spells.character_knows_spell?(character.id, spell.id)

      # Get the inventory item
      inventory_items = Items.get_character_inventory(character.id)
      assert Enum.count(inventory_items) == 1
      inventory_item = hd(inventory_items)

      # Use the scroll to learn the spell
      {:ok, :learned, learned_spell} = Items.use_spell_scroll(character.id, inventory_item.id)
      assert learned_spell.id == spell.id

      # Character should now know the spell
      assert Spells.character_knows_spell?(character.id, spell.id)

      # Verify the spell is in character's spell list
      character_spells = Spells.list_character_spells(character.id)
      assert Enum.count(character_spells) == 1
      assert hd(character_spells).name == "Test Spell"

      # Verify the scroll was consumed
      inventory_items_after = Items.get_character_inventory(character.id)
      assert Enum.empty?(inventory_items_after)
    end

    test "picking up a spell scroll when already knowing the spell doesn't duplicate", %{
      spell: spell,
      scroll: scroll,
      character: character
    } do
      # Teach the spell to the character first
      {:ok, _} = Spells.add_spell_to_character(character.id, spell.id)

      # Place the scroll in a room
      {:ok, room_item} =
        %RoomItem{}
        |> RoomItem.changeset(%{
          location: "0,0,0",
          item_id: scroll.id,
          quantity: 1
        })
        |> Repo.insert()

      # Pick up the scroll
      {:ok, :picked_up} = Items.pick_up_item(character.id, room_item.id)

      # Should still only have one spell
      character_spells = Spells.list_character_spells(character.id)
      assert Enum.count(character_spells) == 1
    end

    test "picking up a regular item (non-scroll) doesn't affect spells", %{character: character} do
      # Create a regular item (no spell_id)
      {:ok, regular_item} =
        Items.create_item(%{
          name: "Health Potion",
          description: "Restores health",
          item_type: "consumable",
          rarity: "common",
          value: 10,
          pickup: true
        })

      # Place the item in a room
      {:ok, room_item} =
        %RoomItem{}
        |> RoomItem.changeset(%{
          location: "0,0,0",
          item_id: regular_item.id,
          quantity: 1
        })
        |> Repo.insert()

      # Pick up the regular item
      {:ok, :picked_up} = Items.pick_up_item(character.id, room_item.id)

      # Should not have learned any spells
      character_spells = Spells.list_character_spells(character.id)
      assert Enum.empty?(character_spells)
    end

    test "spell scrolls are properly seeded" do
      # Check that spell scrolls exist in the database
      scrolls = Repo.all(from i in Item, where: not is_nil(i.spell_id))

      # Should have at least some spell scrolls from seeds
      refute Enum.empty?(scrolls)

      # Check one scroll has the expected properties
      scroll = hd(scrolls)
      assert scroll.item_type == "consumable"
      assert scroll.usable == true
      assert scroll.spell_id != nil
    end
  end
end

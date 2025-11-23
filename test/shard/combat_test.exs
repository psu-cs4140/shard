defmodule Shard.CombatTest do
  use Shard.DataCase

  alias Shard.Combat
  alias Shard.Combat.Engine
  alias Shard.Repo
  alias Shard.Weapons.DamageTypes

  describe "in_combat?/1" do
    test "returns false when combat is not set" do
      game_state = %{}
      refute Combat.in_combat?(game_state)
    end

    test "returns false when combat is false" do
      game_state = %{combat: false}
      refute Combat.in_combat?(game_state)
    end

    test "returns true when combat is true" do
      game_state = %{combat: true}
      assert Combat.in_combat?(game_state)
    end
  end

  describe "execute_action/2" do
    setup do
      game_state = %{
        player_position: {0, 0},
        player_stats: %{strength: 10},
        equipped_weapon: %{damage: 5},
        character: %{name: "TestPlayer", id: 1},
        monsters: []
      }

      %{game_state: game_state}
    end

    test "returns error message for unknown action", %{game_state: game_state} do
      {messages, updated_state} = Combat.execute_action(game_state, "unknown")
      assert messages == ["Unknown combat action."]
      assert updated_state == game_state
    end

    test "handles attack action with no monsters", %{game_state: game_state} do
      # Use integer ID instead of string
      game_state = put_in(game_state.character.id, 1)
      {messages, updated_state} = Combat.execute_action(game_state, "attack")
      assert messages == ["There are no monsters here to attack."]
      assert updated_state == game_state
    end

    test "handles flee action", %{game_state: game_state} do
      # Use integer ID instead of string
      game_state =
        game_state
        |> Map.put(:combat, true)
        |> put_in([:character, :id], 1)

      {messages, updated_state} = Combat.execute_action(game_state, "flee")
      assert messages == ["You flee from combat!"]
      assert updated_state.combat == false
    end
  end

  describe "start_combat/1" do
    test "does nothing when no monsters at position" do
      game_state = %{
        player_position: {0, 0},
        monsters: [%{position: {1, 1}, is_alive: true}]
      }

      {messages, updated_state} = Combat.start_combat(game_state)
      assert messages == []
      assert updated_state == game_state
    end

    test "starts combat when monsters are present" do
      monster = %{
        position: {0, 0},
        is_alive: true,
        name: "Goblin",
        hp: 10,
        hp_max: 10
      }

      game_state = %{
        player_position: {0, 0},
        monsters: [monster],
        combat: false
      }

      {messages, updated_state} = Combat.start_combat(game_state)

      assert length(messages) > 0
      assert String.contains?(Enum.join(messages), "Combat begins!")
      assert String.contains?(Enum.join(messages), "Goblin")
      assert updated_state.combat == true
    end
  end

  describe "Engine.damage/2" do
    test "calculates damage with no variance" do
      cfg = %{base: 10, variance: 0}
      damage = Engine.damage(cfg, 0)
      assert damage == 10
    end

    test "calculates damage with armor reduction" do
      cfg = %{base: 10, variance: 0}
      damage = Engine.damage(cfg, 3)
      assert damage == 7
    end

    test "ensures minimum damage of 1" do
      cfg = %{base: 5, variance: 0}
      damage = Engine.damage(cfg, 10)
      assert damage == 1
    end

    test "applies variance correctly" do
      cfg = %{base: 10, variance: 4}
      # With variance 4, damage should be between 8 and 14 (before armor)
      damage = Engine.damage(cfg, 0)
      assert damage >= 8 and damage <= 14
    end
  end

  describe "Engine.step/1" do
    test "handles empty state" do
      state = %{combat: false, monsters: [], players: [], effects: [], events: []}
      {:ok, new_state, events} = Engine.step(state)
      assert new_state == state
      assert events == []
    end

    test "handles state with monsters and players" do
      monster = %{position: {0, 0}, hp: 10, is_alive: true}
      player = %{id: 1, position: {0, 0}, hp: 10}

      state = %{
        monsters: [monster],
        players: [player],
        effects: [],
        events: [],
        combat: true,
        room_position: {0, 0}
      }

      {:ok, new_state, events} = Engine.step(state)

      # Should return the same state with no effects
      assert new_state.monsters == [monster]
      assert new_state.players == [player]
      assert events == []
    end

    test "applies special damage effects to monsters" do
      monster = %{position: {0, 0}, hp: 10, is_alive: true}
      player = %{id: "player1", position: {0, 0}, hp: 10}

      # Create a poison effect
      effect = %{
        kind: "special_damage",
        target: {:monster, 0},
        remaining_ticks: 3,
        magnitude: 2,
        damage_type: "poison"
      }

      state = %{
        monsters: [monster],
        players: [player],
        effects: [effect],
        events: [],
        combat: true,
        room_position: {0, 0}
      }

      {:ok, new_state, events} = Engine.step(state)

      # Monster should have taken 2 damage
      assert hd(new_state.monsters).hp == 8
      # Effect should have one less tick
      assert hd(new_state.effects).remaining_ticks == 2
      # Should have an event for the effect tick
      assert length(events) == 1
      assert hd(events).type == :effect_tick
      assert hd(events).effect == "poison"
    end

    test "applies special damage effects to players" do
      monster = %{position: {0, 0}, hp: 10, is_alive: true}
      player = %{id: 1, position: {0, 0}, hp: 10}

      # Create a poison effect targeting the player
      effect = %{
        kind: "special_damage",
        target: {:player, 1},
        remaining_ticks: 3,
        magnitude: 2,
        damage_type: "poison"
      }

      state = %{
        monsters: [monster],
        players: [player],
        effects: [effect],
        events: [],
        combat: true,
        room_position: {0, 0}
      }

      {:ok, new_state, events} = Engine.step(state)

      # Player should have taken 2 damage
      assert hd(new_state.players).hp == 8
      # Effect should have one less tick
      assert hd(new_state.effects).remaining_ticks == 2
      # Should have an event for the effect tick
      assert length(events) == 1
      assert hd(events).type == :effect_tick
      assert hd(events).effect == "poison"
    end
  end

  describe "Engine.add_player/2" do
    test "adds new player to combat" do
      state = %{players: []}
      player = %{id: 1, name: "TestPlayer"}

      new_state = Engine.add_player(state, player)

      assert length(new_state.players) == 1
      assert hd(new_state.players).id == 1
    end

    test "doesn't add duplicate player" do
      player = %{id: "player1", name: "TestPlayer"}
      state = %{players: [player]}

      new_state = Engine.add_player(state, player)

      assert length(new_state.players) == 1
    end
  end

  describe "Engine.remove_player/2" do
    test "removes player from combat" do
      player1 = %{id: 1, name: "TestPlayer1"}
      player2 = %{id: 2, name: "TestPlayer2"}
      state = %{players: [player1, player2]}

      new_state = Engine.remove_player(state, 1)

      assert length(new_state.players) == 1
      assert hd(new_state.players).id == 2
    end
  end

  describe "Engine.update_player/3" do
    test "updates player stats" do
      player = %{id: 1, name: "TestPlayer", hp: 10}
      state = %{players: [player]}

      new_state = Engine.update_player(state, 1, %{hp: 5, name: "UpdatedPlayer"})

      updated_player = hd(new_state.players)
      assert updated_player.hp == 5
      assert updated_player.name == "UpdatedPlayer"
    end
  end

  describe "Engine.apply_special_damage_effect/5" do
    test "adds special damage effect to combat state" do
      state = %{effects: []}

      new_state = Engine.apply_special_damage_effect(state, {:player, 1}, "poison", 2, 3)

      assert length(new_state.effects) == 1
      effect = hd(new_state.effects)
      assert effect.kind == "special_damage"
      assert effect.target == {:player, 1}
      assert effect.magnitude == 2
      assert effect.remaining_ticks == 3
      assert effect.damage_type == "poison"
    end
  end

  describe "special damage monsters" do
    setup do
      # Create a poison damage type for testing
      {:ok, poison_type} =
        %DamageTypes{}
        |> DamageTypes.changeset(%{name: "Poison"})
        |> Repo.insert()

      %{
        poison_type: poison_type
      }
    end

    test "creates monster with special damage attributes", %{poison_type: poison_type} do
      attrs = %{
        name: "Poison Spider",
        race: "Arachnid",
        health: 20,
        max_health: 20,
        attack_damage: 3,
        xp_amount: 10,
        level: 2,
        description: "A venomous spider",
        special_damage_type_id: poison_type.id,
        special_damage_amount: 2,
        special_damage_duration: 3,
        special_damage_chance: 50
      }

      {:ok, monster} = Shard.Monsters.create_monster(attrs)

      assert monster.name == "Poison Spider"
      assert monster.special_damage_type_id == poison_type.id
      assert monster.special_damage_amount == 2
      assert monster.special_damage_duration == 3
      assert monster.special_damage_chance == 50
    end

    test "validates special damage attributes", %{poison_type: poison_type} do
      attrs = %{
        name: "Invalid Spider",
        race: "Arachnid",
        health: 20,
        max_health: 20,
        attack_damage: 3,
        xp_amount: 10,
        special_damage_type_id: poison_type.id,
        # Invalid: negative amount
        special_damage_amount: -1,
        special_damage_duration: 3,
        # Invalid: over 100
        special_damage_chance: 150
      }

      {:error, changeset} = Shard.Monsters.create_monster(attrs)

      assert changeset.errors[:special_damage_amount] != nil
      assert changeset.errors[:special_damage_chance] != nil
    end
  end

  describe "private functions" do
    test "parse_damage handles integers" do
      # This tests the private parse_damage function indirectly through execute_action
      game_state = %{
        player_position: {0, 0},
        player_stats: %{strength: 10, health: 100},
        equipped_weapon: %{damage: 5},
        character: %{name: "TestPlayer", id: 1},
        combat: false,
        monsters: [
          %{position: {0, 0}, is_alive: true, name: "TestMonster", hp: 10, armor: 0}
        ]
      }

      {messages, _updated_state} = Combat.execute_action(game_state, "attack")

      # Should successfully attack without crashing on damage parsing
      assert length(messages) > 0
      assert String.contains?(Enum.join(messages), "You attack")
    end
  end
end

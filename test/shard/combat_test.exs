defmodule Shard.CombatTest do
  use ExUnit.Case, async: true
  alias Shard.Combat

  describe "in_combat?/1" do
    test "returns false when no monsters at player position" do
      game_state = %{
        player_position: {0, 0},
        monsters: [%{position: {1, 1}, name: "Goblin"}]
      }

      refute Combat.in_combat?(game_state)
    end

    test "returns true when monsters at player position" do
      game_state = %{
        player_position: {0, 0},
        monsters: [%{position: {0, 0}, name: "Goblin"}]
      }

      assert Combat.in_combat?(game_state)
    end
  end

  describe "monsters_at_position/1" do
    test "returns empty list when no monsters at position" do
      game_state = %{
        player_position: {0, 0},
        monsters: [%{position: {1, 1}, name: "Goblin"}]
      }

      assert Combat.monsters_at_position(game_state) == []
    end

    test "returns monsters at player position" do
      goblin = %{position: {0, 0}, name: "Goblin"}
      orc = %{position: {0, 0}, name: "Orc"}

      game_state = %{
        player_position: {0, 0},
        monsters: [goblin, orc, %{position: {1, 1}, name: "Troll"}]
      }

      result = Combat.monsters_at_position(game_state)
      assert length(result) == 2
      assert goblin in result
      assert orc in result
    end
  end

  describe "start_combat/1" do
    test "returns empty messages and unchanged state when no monsters present" do
      game_state = %{
        player_position: {0, 0},
        monsters: [%{position: {1, 1}}],
        combat: false
      }

      {messages, updated_state} = Combat.start_combat(game_state)

      assert messages == []
      assert updated_state == game_state
    end

    test "starts combat when monsters are present" do
      goblin = %{position: {0, 0}, name: "Goblin", hp: 10, hp_max: 10}

      game_state = %{
        player_position: {0, 0},
        monsters: [goblin],
        combat: false
      }

      {messages, updated_state} = Combat.start_combat(game_state)

      assert length(messages) > 0
      assert updated_state.combat == true
      assert "Combat begins!" in messages
    end
  end

  describe "execute_action/2" do
    test "returns message when not in combat" do
      game_state = %{
        player_position: {0, 0},
        monsters: [%{position: {1, 1}}],
        combat: false
      }

      {messages, updated_state} = Combat.execute_action(game_state, "attack")

      assert messages == ["You are not in combat."]
      assert updated_state == game_state
    end

    test "returns message for unknown action" do
      goblin = %{position: {0, 0}, name: "Goblin"}

      game_state = %{
        player_position: {0, 0},
        monsters: [goblin],
        combat: true
      }

      {messages, updated_state} = Combat.execute_action(game_state, "unknown")

      assert messages == ["Unknown combat action: unknown"]
      assert updated_state == game_state
    end

    test "handles flee action" do
      goblin = %{position: {0, 0}, name: "Goblin"}

      game_state = %{
        player_position: {0, 0},
        monsters: [goblin],
        combat: true
      }

      {messages, updated_state} = Combat.execute_action(game_state, "flee")

      assert messages == ["You attempt to flee..."]
      assert updated_state.combat == false
    end
  end
end

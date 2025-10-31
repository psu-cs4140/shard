defmodule Shard.CombatTest do
  use Shard.DataCase

  alias Shard.Combat

  describe "in_combat?/1" do
    test "returns true when combat is active" do
      game_state = %{combat: true}
      assert Combat.in_combat?(game_state) == true
    end

    test "returns false when combat is not active" do
      game_state = %{combat: false}
      assert Combat.in_combat?(game_state) == false
    end

    test "returns false when combat is nil" do
      game_state = %{combat: nil}
      assert Combat.in_combat?(game_state) == false
    end

    test "returns false when combat key is missing" do
      game_state = %{}
      assert Combat.in_combat?(game_state) == false
    end
  end

  describe "start_combat/1" do
    test "sets combat to true in game state" do
      game_state = %{combat: false}
      result = Combat.start_combat(game_state)
      assert result.combat == true
    end

    test "maintains other game state fields when starting combat" do
      game_state = %{combat: false, player_health: 100, location: "forest"}
      result = Combat.start_combat(game_state)
      assert result.combat == true
      assert result.player_health == 100
      assert result.location == "forest"
    end
  end

  describe "end_combat/1" do
    test "sets combat to false in game state" do
      game_state = %{combat: true}
      result = Combat.end_combat(game_state)
      assert result.combat == false
    end

    test "maintains other game state fields when ending combat" do
      game_state = %{combat: true, player_health: 75, location: "dungeon"}
      result = Combat.end_combat(game_state)
      assert result.combat == false
      assert result.player_health == 75
      assert result.location == "dungeon"
    end
  end

  describe "calculate_damage/2" do
    test "calculates basic damage correctly" do
      attacker = %{attack: 10}
      defender = %{defense: 3}
      damage = Combat.calculate_damage(attacker, defender)
      assert damage == 7
    end

    test "returns minimum damage of 1 when defense exceeds attack" do
      attacker = %{attack: 5}
      defender = %{defense: 10}
      damage = Combat.calculate_damage(attacker, defender)
      assert damage == 1
    end

    test "handles zero defense correctly" do
      attacker = %{attack: 15}
      defender = %{defense: 0}
      damage = Combat.calculate_damage(attacker, defender)
      assert damage == 15
    end
  end
end

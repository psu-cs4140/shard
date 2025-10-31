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
end

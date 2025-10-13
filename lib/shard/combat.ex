defmodule Shard.Combat do
  @moduledoc false
  @type game_state :: map()

  def monsters_at_position(%{player_position: pos, monsters: mons}) do
    mons |> List.wrap() |> Enum.filter(fn m -> Map.get(m, :position) == pos end)
  end

  def monsters_at_position(_), do: []

  def in_combat?(state), do: monsters_at_position(state) != []

  def start_combat(state) do
    if in_combat?(state),
      do: {["Combat begins!"], Map.put(state, :combat, true)},
      else: {[], state}
  end

  def execute_action(state, action) do
    if Map.get(state, :combat, false) do
      case normalize_action(action) do
        "attack" ->
          if monsters_at_position(state) == [],
            do: {["No targets in range."], state},
            else: {["You attack the enemy."], state}

        "flee" ->
          {["You attempt to flee..."], Map.put(state, :combat, false)}

        other ->
          {["Unknown combat action: " <> other], state}
      end
    else
      {["You are not in combat."], state}
    end
  end

  defp normalize_action(a) when is_binary(a), do: String.downcase(a)
  defp normalize_action(a) when is_atom(a), do: a |> Atom.to_string() |> String.downcase()
  defp normalize_action(_), do: "unknown"
end

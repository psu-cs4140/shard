defmodule Shard.Combat do
  @moduledoc false
  alias Shard.Combat.Engine

  @type game_state :: map()

  # -------- Query helpers (unchanged signatures to keep tests stable) --------
  def monsters_at_position(%{player_position: pos, monsters: mons}) do
    mons |> List.wrap() |> Enum.filter(fn m -> Map.get(m, :position) == pos end)
  end

  def monsters_at_position(_), do: []

  def in_combat?(state), do: monsters_at_position(state) != []

  # -------- Public API expected by existing code/tests --------
  def start_combat(state) do
    if in_combat?(state),
      do: {["Combat begins!"], Map.put(state, :combat, true) |> ensure_effects()},
      else: {[], state |> ensure_effects()}
  end

  def execute_action(state, action) do
    if Map.get(state, :combat, false) do
      case normalize_action(action) do
        "attack" -> do_attack(state)
        "flee" -> {["You attempt to flee..."], Map.put(state, :combat, false)}
        other -> {["Unknown combat action: " <> other], state}
      end
    else
      {["You are not in combat."], state}
    end
  end

  # Expose a manual tick for effects/periodic resolution (optional call site)
  def tick(state) do
    {:ok, s2, _events} = Engine.step(ensure_effects(state))
    {[], s2}
  end

  # -------- Internals --------
  defp do_attack(state) do
    pos = state[:player_position]

    case first_target_at_pos(state[:monsters], pos) do
      nil ->
        {["No targets in range."], state}

      {idx, m} ->
        armor = Map.get(m, :armor, 0)
        dmg = Engine.damage(%{base: 4, variance: 2}, armor)
        hp = max((m[:hp] || 10) - dmg, 0)
        m2 = m |> Map.put(:hp, hp) |> Map.put(:is_alive, hp > 0)
        mons2 = List.replace_at(state[:monsters], idx, m2)
        s2 = %{ensure_effects(state) | monsters: mons2}

        # Optional: attach a light bleed so periodic effects do something
        s3 = attach_bleed_if_alive(s2, idx, m2)

        # Winner resolution without changing the message contract
        any_alive_here? =
          monsters_at_position(s3)
          |> Enum.any?(fn x -> Map.get(x, :is_alive, true) end)

        s4 = if any_alive_here?, do: s3, else: %{s3 | combat: false}

        {["You attack the enemy."], s4}
    end
  end

  defp attach_bleed_if_alive(state, idx, %{is_alive: true}) do
    eff = %{kind: "bleed", target: {:monster, idx}, remaining_ticks: 2, magnitude: 1}
    Map.update!(state, :effects, fn list -> [eff | list] end)
  end

  defp attach_bleed_if_alive(state, _idx, _), do: state

  defp first_target_at_pos(mons, pos) do
    mons
    |> List.wrap()
    |> Enum.with_index()
    |> Enum.find_value(fn {m, i} -> if m[:position] == pos, do: {i, m}, else: nil end)
  end

  defp normalize_action(a) when is_binary(a), do: String.downcase(a)
  defp normalize_action(a) when is_atom(a), do: a |> Atom.to_string() |> String.downcase()
  defp normalize_action(_), do: "unknown"

  defp ensure_effects(state), do: Map.put_new(state, :effects, [])
end

# credo:disable-for-this-file Credo.Check.Refactor.Nesting
# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule Shard.Combat.Engine do
  @moduledoc false

  @type dmg_cfg :: %{base: non_neg_integer(), variance: non_neg_integer()}

  @doc "Flat armor reduction with floor 1. Returns an integer damage."
  def damage(%{base: base, variance: var}, armor)
      when base >= 0 and var >= 0 and is_integer(armor) and armor >= 0 do
    roll = if var == 0, do: 0, else: :rand.uniform(var + 1) - 1
    max(base + roll - armor, 1)
  end

  @doc """
  Advance combat one tick: apply periodic effects (e.g., bleed), resolve deaths,
  and end combat if no living targets remain at the player's position.

  State shape expected:
    %{
      player_position: {x,y},
      monsters: [%{position: {x,y}, hp: int, is_alive: bool, armor: int, name: String.t()}],
      effects: [%{kind: "bleed", target: {:monster, index}, remaining_ticks: int, magnitude: int}],
      combat: bool
    }
  """
  def step(state) do
    state
    |> apply_effects()
    |> resolve_deaths_and_victory()
  end

  defp apply_effects(state) do
    effects = Map.get(state, :effects, [])

    {monsters2, effects2, events} =
      Enum.reduce(effects, {state.monsters || [], [], []}, fn eff, {mons, keep, evs} ->
        case eff do
          %{kind: "bleed", target: {:monster, i}, remaining_ticks: t, magnitude: mag}
          when t > 0 ->
            case Enum.fetch(mons, i) do
              {:ok, m} ->
                if alive?(m) do
                  hp = max((m[:hp] || 10) - mag, 0)
                  m2 = m |> Map.put(:hp, hp) |> Map.put(:is_alive, hp > 0)
                  mons2 = List.replace_at(mons, i, m2)
                  eff2 = %{eff | remaining_ticks: t - 1}
                  ev = %{type: :effect_tick, effect: "bleed", target: {:monster, i}, dmg: mag}
                  {mons2, if(eff2.remaining_ticks > 0, do: [eff2 | keep], else: keep), [ev | evs]}
                else
                  # target already dead; drop effect
                  {mons, keep, evs}
                end

              :error ->
                # target index out of range; drop effect
                {mons, keep, evs}
            end

          _other ->
            # unknown effect; keep it but decrement if it has remaining_ticks
            eff2 =
              case eff do
                %{remaining_ticks: t} when is_integer(t) and t > 0 ->
                  Map.put(eff, :remaining_ticks, t - 1)

                _ ->
                  eff
              end

            {mons, [eff2 | keep], evs}
        end
      end)

    %{state | monsters: monsters2, effects: Enum.reverse(effects2), events: Enum.reverse(events)}
  end

  defp resolve_deaths_and_victory(state) do
    pos = state[:player_position]

    alive_here? =
      state[:monsters]
      |> List.wrap()
      |> Enum.any?(fn m -> m[:position] == pos and alive?(m) end)

    # credo:disable-for-next-line Credo.Check.Readability.CondStatements
    cond do
      state[:combat] && !alive_here? ->
        {:ok, %{state | combat: false}, (state[:events] || []) ++ [%{type: :win}]}

      true ->
        {:ok, %{state | events: state[:events] || []}, state[:events] || []}
    end
  end

  defp alive?(%{is_alive: false}), do: false
  defp alive?(%{hp: hp}) when is_integer(hp), do: hp > 0
  defp alive?(_), do: true
end

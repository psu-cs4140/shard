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
      players: [%{id: String.t(), position: {x,y}, hp: int, max_hp: int, name: String.t()}],
      monsters: [%{position: {x,y}, hp: int, is_alive: bool, armor: int, name: String.t()}],
      effects: [%{kind: "bleed", target: {:monster, index} | {:player, id}, remaining_ticks: int, magnitude: int}],
      combat: bool,
      room_position: {x,y}
    }
  """
  def step(state) do
    state
    |> apply_effects()
    |> resolve_deaths_and_victory()
  end

  defp apply_effect_event_damage(monsters, events) do
    Enum.reduce(events, {monsters, []}, fn ev, {mons, acc} ->
      case ev do
        # Bleed tick against a monster index; dmg currently stores pre-armor magnitude
        %{type: :effect_tick, effect: "bleed", target: {:monster, i}, dmg: mag} ->
          target = if is_integer(i), do: Enum.at(mons, i), else: nil
          armor = if is_map(target), do: Map.get(target, :armor, 0), else: 0
          # Use existing armor-aware damage() with zero variance for ticks
          dmg2 = damage(%{base: mag, variance: 0}, armor)

          mons2 =
            if is_map(target) do
              List.update_at(mons, i, fn m ->
                hp2 = max(Map.get(m, :hp, 0) - dmg2, 0)
                m2 = Map.put(m, :hp, hp2)
                if hp2 <= 0, do: Map.put(m2, :is_alive, false), else: m2
              end)
            else
              mons
            end

          {mons2, [Map.put(ev, :dmg, dmg2) | acc]}

        _ ->
          {mons, [ev | acc]}
      end
    end)
  end

  defp apply_effects(state) do
    effects = Map.get(state, :effects, [])

    {monsters2, players2, effects2, events} =
      Enum.reduce(effects, {state.monsters || [], state.players || [], [], []}, fn eff,
                                                                                   {mons, plrs,
                                                                                    keep, evs} ->
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

                  {mons2, plrs, if(eff2.remaining_ticks > 0, do: [eff2 | keep], else: keep),
                   [ev | evs]}
                else
                  # target already dead; drop effect
                  {mons, plrs, keep, evs}
                end

              :error ->
                # target index out of range; drop effect
                {mons, plrs, keep, evs}
            end

          %{kind: "bleed", target: {:player, player_id}, remaining_ticks: t, magnitude: mag}
          when t > 0 ->
            case Enum.find_index(plrs, &(&1.id == player_id)) do
              nil ->
                # player not found; drop effect
                {mons, plrs, keep, evs}

              i ->
                p = Enum.at(plrs, i)

                if alive_player?(p) do
                  hp = max((p[:hp] || 10) - mag, 0)
                  p2 = Map.put(p, :hp, hp)
                  plrs2 = List.replace_at(plrs, i, p2)
                  eff2 = %{eff | remaining_ticks: t - 1}

                  ev = %{
                    type: :effect_tick,
                    effect: "bleed",
                    target: {:player, player_id},
                    dmg: mag
                  }

                  {mons, plrs2, if(eff2.remaining_ticks > 0, do: [eff2 | keep], else: keep),
                   [ev | evs]}
                else
                  # player already dead; drop effect
                  {mons, plrs, keep, evs}
                end
            end

          # NEW: Special damage effects (poison, burn, etc.)
          %{
            kind: "special_damage",
            target: {:monster, i},
            remaining_ticks: t,
            magnitude: mag,
            damage_type: type
          }
          when t > 0 ->
            case Enum.fetch(mons, i) do
              {:ok, m} ->
                if alive?(m) do
                  hp = max((m[:hp] || 10) - mag, 0)
                  m2 = m |> Map.put(:hp, hp) |> Map.put(:is_alive, hp > 0)
                  mons2 = List.replace_at(mons, i, m2)
                  eff2 = %{eff | remaining_ticks: t - 1}
                  ev = %{type: :effect_tick, effect: type, target: {:monster, i}, dmg: mag}

                  {mons2, plrs, if(eff2.remaining_ticks > 0, do: [eff2 | keep], else: keep),
                   [ev | evs]}
                else
                  # target already dead; drop effect
                  {mons, plrs, keep, evs}
                end

              :error ->
                # target index out of range; drop effect
                {mons, plrs, keep, evs}
            end

          %{
            kind: "special_damage",
            target: {:player, player_id},
            remaining_ticks: t,
            magnitude: mag,
            damage_type: type
          }
          when t > 0 ->
            case Enum.find_index(plrs, &(&1.id == player_id)) do
              nil ->
                # player not found; drop effect
                {mons, plrs, keep, evs}

              i ->
                p = Enum.at(plrs, i)

                if alive_player?(p) do
                  hp = max((p[:hp] || 10) - mag, 0)
                  p2 = Map.put(p, :hp, hp)
                  plrs2 = List.replace_at(plrs, i, p2)
                  eff2 = %{eff | remaining_ticks: t - 1}

                  ev = %{
                    type: :effect_tick,
                    effect: type,
                    target: {:player, player_id},
                    dmg: mag
                  }

                  {mons, plrs2, if(eff2.remaining_ticks > 0, do: [eff2 | keep], else: keep),
                   [ev | evs]}
                else
                  # player already dead; drop effect
                  {mons, plrs, keep, evs}
                end
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

            {mons, plrs, [eff2 | keep], evs}
        end
      end)

    {monsters3, events2} = apply_effect_event_damage(monsters2, events)

    %{
      state
      | monsters: monsters3,
        players: players2,
        effects: Enum.reverse(effects2),
        events: Enum.reverse(events2)
    }
  end

  defp resolve_deaths_and_victory(state) do
    room_pos = state[:room_position]

    # Get monsters that were originally at this position when combat started
    original_monsters_here =
      state[:monsters]
      |> List.wrap()
      |> Enum.filter(fn m -> m[:position] == room_pos end)

    # Process item drops from newly dead monsters
    {state_with_drops, drop_events} = process_monster_drops(state, original_monsters_here)

    # Check if there are any alive monsters at this position
    alive_monsters_here? =
      original_monsters_here
      |> Enum.any?(fn m -> alive?(m) end)

    alive_players_here? =
      state_with_drops[:players]
      |> List.wrap()
      |> Enum.any?(fn p -> p[:position] == room_pos and alive_player?(p) end)

    # Only trigger victory/defeat if we actually had monsters here to begin with
    has_monsters_at_position? = length(original_monsters_here) > 0

    all_events = (state_with_drops[:events] || []) ++ drop_events

    cond do
      state_with_drops[:combat] && has_monsters_at_position? && !alive_monsters_here? &&
          alive_players_here? ->
        # All monsters dead and players alive - victory for players
        require Logger

        Logger.info(
          "Victory triggered - Room: #{inspect(room_pos)}, Original monsters: #{length(original_monsters_here)}, Alive monsters: #{alive_monsters_here?}"
        )

        {:ok, %{state_with_drops | combat: false}, all_events ++ [%{type: :victory}]}

      state_with_drops[:combat] && has_monsters_at_position? && !alive_players_here? ->
        # All players dead - defeat
        {:ok, %{state_with_drops | combat: false}, all_events ++ [%{type: :defeat}]}

      true ->
        {:ok, %{state_with_drops | events: all_events}, all_events}
    end
  end

  defp alive?(%{is_alive: false}), do: false
  defp alive?(%{hp: hp}) when is_integer(hp), do: hp > 0
  defp alive?(_), do: true

  defp alive_player?(%{hp: hp}) when is_integer(hp), do: hp > 0
  defp alive_player?(_), do: true

  @doc """
  Add a player to the combat state.
  """
  def add_player(state, player) do
    players = Map.get(state, :players, [])

    # Check if player is already in combat
    case Enum.find(players, &(&1.id == player.id)) do
      nil ->
        # Add new player
        updated_players = [player | players]
        Map.put(state, :players, updated_players)

      _existing ->
        # Player already in combat, don't add again
        state
    end
  end

  @doc """
  Remove a player from the combat state.
  """
  def remove_player(state, player_id) do
    players = Map.get(state, :players, [])
    updated_players = Enum.reject(players, &(&1.id == player_id))
    Map.put(state, :players, updated_players)
  end

  @doc """
  Update a player's stats in the combat state.
  """
  def update_player(state, player_id, updates) do
    players = Map.get(state, :players, [])

    updated_players =
      Enum.map(players, fn p ->
        if p.id == player_id do
          Map.merge(p, updates)
        else
          p
        end
      end)

    Map.put(state, :players, updated_players)
  end

  @doc """
  Apply a special damage effect to the combat state.
  """
  def apply_special_damage_effect(combat_state, target, damage_type, amount, duration) do
    effect = %{
      kind: "special_damage",
      target: target,
      remaining_ticks: duration,
      magnitude: amount,
      damage_type: damage_type
    }

    effects = Map.get(combat_state, :effects, [])
    %{combat_state | effects: [effect | effects]}
  end

  defp process_monster_drops(state, monsters) do
    # Find monsters that just died (have is_alive: false but haven't been processed yet)
    newly_dead_monsters =
      monsters
      |> Enum.with_index()
      |> Enum.filter(fn {monster, _index} ->
        not alive?(monster) and not Map.get(monster, :drops_processed, false)
      end)

    # Process drops for each newly dead monster
    {updated_state, drop_events} =
      Enum.reduce(newly_dead_monsters, {state, []}, fn {monster, monster_index},
                                                       {acc_state, acc_events} ->
        # Mark this monster as having drops processed
        updated_monsters =
          List.update_at(acc_state[:monsters], monster_index, fn m ->
            Map.put(m, :drops_processed, true)
          end)

        temp_state = Map.put(acc_state, :monsters, updated_monsters)

        # Process potential loot drops
        case Map.get(monster, :potential_loot_drops, %{}) do
          drops when map_size(drops) > 0 ->
            # Generate drops and create events
            {final_state, events} = generate_monster_drops(temp_state, monster, drops)
            {final_state, acc_events ++ events}

          _ ->
            # No drops to process
            {temp_state, acc_events}
        end
      end)

    {updated_state, drop_events}
  end

  defp generate_monster_drops(state, monster, potential_drops) do
    # Get players at the same position as the monster
    players_here =
      state[:players]
      |> List.wrap()
      |> Enum.filter(fn p ->
        p[:position] == monster[:position] and alive_player?(p)
      end)

    # Generate actual drops based on potential_loot_drops
    actual_drops =
      potential_drops
      |> Enum.flat_map(fn {item_id, drop_chance} ->
        # Convert drop_chance to integer if it's a string
        chance =
          case drop_chance do
            chance when is_integer(chance) -> chance
            chance when is_binary(chance) -> String.to_integer(chance)
            _ -> 0
          end

        # Roll for drop (1-100)
        if :rand.uniform(100) <= chance do
          # Drop 1 of this item
          [{item_id, 1}]
        else
          []
        end
      end)

    # Create drop events for each item that dropped
    drop_events =
      actual_drops
      |> Enum.map(fn {item_id, quantity} ->
        %{
          type: :monster_drop,
          monster_name: Map.get(monster, :name, "Unknown Monster"),
          item_id: item_id,
          quantity: quantity,
          players: Enum.map(players_here, & &1.id)
        }
      end)

    {state, drop_events}
  end
end

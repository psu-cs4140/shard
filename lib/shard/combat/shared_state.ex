defmodule Shard.Combat.SharedState do
  @moduledoc """
  Manages shared combat state across multiple players.
  """

  def get_shared_combat_state(combat_id) do
    try do
      # Check if the process exists first
      case Registry.lookup(Shard.Registry, {:combat, combat_id}) do
        [] ->
          # Process doesn't exist
          nil

        [{_pid, _}] ->
          # Process exists, try to get state
          Shard.Combat.Server.get_combat_state(combat_id)
      end
    rescue
      _ -> nil
    catch
      :exit, _ -> nil
    end
  end

  def ensure_shared_combat_state(combat_id, position, monsters) do
    case get_shared_combat_state(combat_id) do
      nil ->
        # Ensure we only work with the provided monsters list, not any cached state
        provided_monsters = monsters || []

        # Filter monsters to only include those at the current position
        # Create deep copies to avoid test state pollution
        monsters_at_position =
          provided_monsters
          |> Enum.filter(fn monster ->
            monster[:position] == position && monster[:is_alive] != false
          end)
          |> Enum.map(fn monster ->
            # Create a fresh copy of each monster to avoid shared state in tests
            Map.new(monster)
          end)

        # Start new combat server
        initial_state = %{
          combat_id: combat_id,
          room_position: position,
          monsters: monsters_at_position,
          players: [],
          effects: [],
          combat: true
        }

        # Check if supervisor is available before trying to start child
        case Process.whereis(Shard.Combat.Supervisor) do
          nil ->
            # Supervisor not available, fall back to local state with monsters
            {:ok, initial_state}

          _pid ->
            # Use the correct child spec format for DynamicSupervisor
            child_spec = %{
              # Make ID unique per combat
              id: {Shard.Combat.Server, combat_id},
              start: {Shard.Combat.Server, :start_link, [initial_state]},
              restart: :temporary
            }

            case DynamicSupervisor.start_child(Shard.Combat.Supervisor, child_spec) do
              {:ok, _pid} ->
                # Wait a moment for the process to initialize
                :timer.sleep(10)
                {:ok, initial_state}

              {:error, {:already_started, _pid}} ->
                {:ok, get_shared_combat_state(combat_id) || initial_state}

              _error ->
                # Fall back to local state if server start fails
                {:ok, initial_state}
            end
        end

      state ->
        {:ok, state}
    end
  end

  def add_player_to_shared_combat(combat_id, player_data) do
    try do
      # Check if the process exists first
      case Registry.lookup(Shard.Registry, {:combat, combat_id}) do
        [] ->
          :error

        [{_pid, _}] ->
          Shard.Combat.Server.add_player(combat_id, player_data)
      end
    rescue
      _ -> :error
    catch
      :exit, _ -> :error
    end
  end

  def update_shared_monster_state(combat_id, original_monster, updated_monster) do
    try do
      # Check if the process exists first
      case Registry.lookup(Shard.Registry, {:combat, combat_id}) do
        [] ->
          :error

        [{_pid, _}] ->
          # Get current combat state
          case get_shared_combat_state(combat_id) do
            nil ->
              :error

            combat_state ->
              # Update the monster in the monsters list
              updated_monsters =
                update_monsters_list(
                  combat_state.monsters || [],
                  original_monster,
                  updated_monster
                )

              # Update the combat state
              GenServer.call(
                Shard.Combat.Server.via(combat_id),
                {:update_monsters, updated_monsters}
              )
          end
      end
    rescue
      _ -> :error
    catch
      :exit, _ -> :error
    end
  end

  def update_shared_player_state(combat_id, player_id, updates) do
    try do
      # Check if the process exists first
      case Registry.lookup(Shard.Registry, {:combat, combat_id}) do
        [] ->
          :error

        [{_pid, _}] ->
          Shard.Combat.Server.update_player(combat_id, player_id, updates)
      end
    rescue
      _ -> :error
    catch
      :exit, _ -> :error
    end
  end

  def remove_shared_monster(combat_id, dead_monster) do
    try do
      # Check if the process exists first
      case Registry.lookup(Shard.Registry, {:combat, combat_id}) do
        [] ->
          :error

        [{_pid, _}] ->
          case get_shared_combat_state(combat_id) do
            nil ->
              :error

            combat_state ->
              updated_monsters =
                Enum.reject(combat_state.monsters || [], fn m ->
                  m[:position] == dead_monster[:position] and
                    m[:monster_id] == dead_monster[:monster_id]
                end)

              GenServer.call(
                Shard.Combat.Server.via(combat_id),
                {:update_monsters, updated_monsters}
              )
          end
      end
    rescue
      _ -> :error
    catch
      :exit, _ -> :error
    end
  end

  defp update_monsters_list(monsters, original_monster, updated_monster) do
    Enum.map(monsters, fn m ->
      if m == original_monster, do: updated_monster, else: m
    end)
  end
end

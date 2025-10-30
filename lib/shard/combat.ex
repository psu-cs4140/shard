defmodule Shard.Combat do
  @moduledoc """
  Combat system for handling player vs monster battles.
  """
  
  alias Phoenix.PubSub
  
  def in_combat?(game_state) do
    game_state.combat || false
  end
  
  def execute_action(game_state, action) do
    case action do
      "attack" ->
        execute_attack(game_state)
      
      "flee" ->
        execute_flee(game_state)
      
      _ ->
        {["Unknown combat action."], game_state}
    end
  end
  
  defp execute_attack(game_state) do
    {x, y} = game_state.player_position
    
    # Find monsters at current location
    monsters_here = Enum.filter(game_state.monsters, fn monster ->
      monster[:position] == {x, y} && monster[:is_alive] != false
    end)
    
    case monsters_here do
      [] ->
        {["There are no monsters here to attack."], game_state}
      
      [monster | _] ->
        # Calculate damage
        base_damage = 10 + (game_state.player_stats.strength - 10)
        variance = 5
        actual_damage = max(base_damage + :rand.uniform(variance) - div(variance, 2), 1)
        
        # Apply armor reduction
        armor = monster[:armor] || 0
        final_damage = max(actual_damage - armor, 1)
        
        # Update monster health
        new_hp = max((monster[:hp] || 10) - final_damage, 0)
        is_alive = new_hp > 0
        
        updated_monster = monster
          |> Map.put(:hp, new_hp)
          |> Map.put(:is_alive, is_alive)
        
        # Update monsters list
        updated_monsters = Enum.map(game_state.monsters, fn m ->
          if m == monster, do: updated_monster, else: m
        end)
        
        # Create combat messages
        monster_name = monster[:name] || "monster"
        attack_msg = "You attack the #{monster_name} for #{final_damage} damage!"
        
        response = if is_alive do
          [attack_msg, "The #{monster_name} has #{new_hp} health remaining."]
        else
          [attack_msg, "The #{monster_name} is defeated!"]
        end
        
        # Broadcast attack event to other players in the room
        broadcast_combat_event({x, y}, {
          :player_attack, 
          game_state.character.name, 
          monster_name, 
          final_damage, 
          is_alive
        })
        
        # Set combat state
        updated_game_state = %{game_state | 
          monsters: updated_monsters,
          combat: Enum.any?(updated_monsters, fn m -> 
            m[:position] == {x, y} && m[:is_alive] != false 
          end)
        }
        
        {response, updated_game_state}
    end
  end
  
  defp execute_flee(game_state) do
    # Simple flee mechanic - always succeeds for now
    updated_game_state = %{game_state | combat: false}
    
    # Broadcast flee event
    {x, y} = game_state.player_position
    broadcast_combat_event({x, y}, {:player_fled, game_state.character.name})
    
    {["You flee from combat!"], updated_game_state}
  end
  
  defp broadcast_combat_event({x, y}, event) do
    channel = "room:#{x}:#{y}"
    PubSub.broadcast(Shard.PubSub, channel, {:combat_action, event})
  end
end

defmodule Shard.WorldTime.TimeEffects do
  @moduledoc """
  Module for applying time-based effects to rooms and NPCs.
  """

  alias Shard.WorldTime

  @doc """
  Gets the current lighting description for a room based on time of day.
  """
  def get_room_lighting_description(room) do
    base_lighting = Map.get(room.properties, "base_lighting", "normal")
    time_of_day = WorldTime.get_time_of_day()

    case {base_lighting, time_of_day} do
      {"dark", _} -> "The room is shrouded in darkness."
      {"bright", _} -> "The room is brightly illuminated."
      {_, :dawn} -> "Soft dawn light filters into the room."
      {_, :day} -> "The room is well-lit by daylight."
      {_, :dusk} -> "The room is dimly lit by the fading light of dusk."
      {_, :night} -> "The room is dark, with only faint moonlight providing visibility."
      _ -> "The room has normal lighting."
    end
  end

  @doc """
  Modifies room description based on current time of day.
  """
  def get_time_modified_room_description(room) do
    base_description = room.description || ""
    lighting_desc = get_room_lighting_description(room)
    
    "#{base_description} #{lighting_desc}"
  end

  @doc """
  Gets time-based behavior modifiers for an NPC.
  Returns a map with behavior modifications.
  """
  def get_npc_time_modifiers(npc) do
    time_of_day = WorldTime.get_time_of_day()
    npc_behavior = Map.get(npc.properties, "time_behavior", %{})
    
    base_modifiers = %{
      aggression_modifier: 0,
      movement_modifier: 1.0,
      dialogue_variant: nil,
      visibility_modifier: 1.0
    }

    time_specific_modifiers = case time_of_day do
      :night -> 
        %{
          aggression_modifier: Map.get(npc_behavior, "night_aggression_bonus", 1),
          movement_modifier: Map.get(npc_behavior, "night_movement_modifier", 0.8),
          dialogue_variant: Map.get(npc_behavior, "night_dialogue"),
          visibility_modifier: 0.5
        }
      :dawn ->
        %{
          movement_modifier: Map.get(npc_behavior, "dawn_movement_modifier", 1.2),
          dialogue_variant: Map.get(npc_behavior, "dawn_dialogue")
        }
      :dusk ->
        %{
          aggression_modifier: Map.get(npc_behavior, "dusk_aggression_bonus", 0),
          dialogue_variant: Map.get(npc_behavior, "dusk_dialogue")
        }
      :day ->
        %{
          dialogue_variant: Map.get(npc_behavior, "day_dialogue")
        }
    end

    Map.merge(base_modifiers, time_specific_modifiers)
  end

  @doc """
  Gets the effective aggression level for an NPC based on time of day.
  """
  def get_effective_aggression(npc) do
    modifiers = get_npc_time_modifiers(npc)
    base_aggression = npc.aggression_level || 0
    aggression_modifier = modifiers.aggression_modifier || 0
    
    max(0, min(10, base_aggression + aggression_modifier))
  end

  @doc """
  Gets time-appropriate dialogue for an NPC.
  """
  def get_time_appropriate_dialogue(npc) do
    modifiers = get_npc_time_modifiers(npc)
    
    case modifiers.dialogue_variant do
      nil -> npc.dialogue
      variant_dialogue -> variant_dialogue
    end
  end

  @doc """
  Checks if an NPC should be more active based on time of day.
  """
  def is_npc_more_active?(npc) do
    modifiers = get_npc_time_modifiers(npc)
    movement_modifier = modifiers.movement_modifier || 1.0
    
    movement_modifier > 1.0
  end
end

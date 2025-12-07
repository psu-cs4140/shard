defmodule Shard.WorldTime do
  @moduledoc """
  The WorldTime context - manages the game world's time cycle and time-based effects.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo
  alias Shard.WorldTime.TimeCycle

  @doc """
  Gets the current world time state.
  Creates a default time cycle if none exists.
  """
  def get_current_time do
    case Repo.one(TimeCycle) do
      nil -> create_default_time_cycle()
      time_cycle -> time_cycle
    end
  end

  @doc """
  Updates the world time by advancing it by the specified minutes.
  """
  def advance_time(minutes \\ 1) do
    current_time = get_current_time()
    new_minutes = current_time.current_minute + minutes
    
    # Calculate new time values
    {new_hour, remaining_minutes} = calculate_new_hour(current_time.current_hour, new_minutes)
    {new_day, final_hour} = calculate_new_day(current_time.current_day, new_hour)
    
    # Update the time cycle
    current_time
    |> TimeCycle.changeset(%{
      current_minute: rem(remaining_minutes, 60),
      current_hour: final_hour,
      current_day: new_day
    })
    |> Repo.update()
  end

  @doc """
  Gets the current time of day as an atom.
  Returns :dawn, :day, :dusk, or :night
  """
  def get_time_of_day do
    current_time = get_current_time()
    
    case current_time.current_hour do
      hour when hour >= 6 and hour < 8 -> :dawn
      hour when hour >= 8 and hour < 18 -> :day
      hour when hour >= 18 and hour < 20 -> :dusk
      _ -> :night
    end
  end

  @doc """
  Gets lighting level based on current time of day.
  Returns a value between 0.0 (complete darkness) and 1.0 (full daylight)
  """
  def get_lighting_level do
    case get_time_of_day() do
      :dawn -> 0.6
      :day -> 1.0
      :dusk -> 0.4
      :night -> 0.1
    end
  end

  @doc """
  Checks if it's currently nighttime
  """
  def is_night? do
    get_time_of_day() == :night
  end

  @doc """
  Checks if it's currently daytime
  """
  def is_day? do
    get_time_of_day() == :day
  end

  defp create_default_time_cycle do
    %TimeCycle{}
    |> TimeCycle.changeset(%{
      current_minute: 0,
      current_hour: 12,  # Start at noon
      current_day: 1
    })
    |> Repo.insert!()
  end

  defp calculate_new_hour(current_hour, new_minutes) do
    additional_hours = div(new_minutes, 60)
    remaining_minutes = rem(new_minutes, 60)
    new_hour = current_hour + additional_hours
    
    if new_hour >= 24 do
      {rem(new_hour, 24), remaining_minutes}
    else
      {new_hour, remaining_minutes}
    end
  end

  defp calculate_new_day(current_day, new_hour) do
    if new_hour >= 24 do
      additional_days = div(new_hour, 24)
      final_hour = rem(new_hour, 24)
      {current_day + additional_days, final_hour}
    else
      {current_day, new_hour}
    end
  end
end

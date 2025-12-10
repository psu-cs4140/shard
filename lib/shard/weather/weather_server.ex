defmodule Shard.Weather.WeatherServer do
  @moduledoc """
  GenServer that manages dynamic weather changes across all zones.
  """

  use GenServer
  alias Shard.Weather
  alias Shard.Weather.Weather, as: WeatherSchema

  # Weather changes every 15-45 minutes
  # 15 minutes in ms
  @weather_change_interval_min 15 * 60 * 1000
  # 45 minutes in ms
  @weather_change_interval_max 45 * 60 * 1000

  # Cleanup expired weather every 10 minutes
  # 10 minutes in ms
  @cleanup_interval 10 * 60 * 1000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_weather_for_zone(zone_id) do
    GenServer.call(__MODULE__, {:get_weather, zone_id})
  end

  def force_weather_change(zone_id, weather_type, intensity \\ nil) do
    GenServer.cast(__MODULE__, {:force_weather_change, zone_id, weather_type, intensity})
  end

  @impl true
  def init(_opts) do
    # Schedule initial weather generation and cleanup
    schedule_weather_change()
    schedule_cleanup()

    {:ok, %{}}
  end

  @impl true
  def handle_call({:get_weather, zone_id}, _from, state) do
    weather = Weather.get_active_weather_for_zone(zone_id)
    {:reply, weather, state}
  end

  @impl true
  def handle_cast({:force_weather_change, zone_id, weather_type, intensity}, state) do
    intensity = intensity || Enum.random(1..3)
    create_weather_for_zone(zone_id, weather_type, intensity)
    {:noreply, state}
  end

  @impl true
  def handle_info(:weather_change, state) do
    generate_random_weather_changes()
    schedule_weather_change()
    {:noreply, state}
  end

  @impl true
  def handle_info(:cleanup, state) do
    Weather.cleanup_expired_weather()
    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_weather_change do
    interval = Enum.random(@weather_change_interval_min..@weather_change_interval_max)
    Process.send_after(self(), :weather_change, interval)
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end

  defp generate_random_weather_changes do
    # Get all zones - for now using hardcoded zone IDs
    # TODO: Replace with actual zone fetching from Map context
    # Example zone ID
    zone_ids = ["01234567-89ab-cdef-0123-456789abcdef"]

    # Change weather in 20-40% of zones
    zones_to_change =
      Enum.take_random(zone_ids, max(1, div(length(zone_ids) * Enum.random(20..40), 100)))

    Enum.each(zones_to_change, fn zone_id ->
      weather_type = Enum.random(WeatherSchema.weather_types())
      # Rarely use intensity 5
      intensity = Enum.random(1..4)
      create_weather_for_zone(zone_id, weather_type, intensity)
    end)
  end

  defp create_weather_for_zone(zone_id, weather_type, intensity) do
    # 20-60 minutes
    duration = Enum.random(20..60)

    attrs = %{
      zone_id: zone_id,
      weather_type: weather_type,
      intensity: intensity,
      duration_minutes: duration,
      started_at: DateTime.utc_now(),
      effects: WeatherSchema.get_weather_effects(weather_type, intensity)
    }

    Weather.create_weather(attrs)
  end
end

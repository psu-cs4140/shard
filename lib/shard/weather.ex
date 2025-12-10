defmodule Shard.Weather do
  @moduledoc """
  The Weather context - manages weather conditions across zones.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo
  alias Shard.Weather.Weather

  def get_weather_for_zone(zone_id) do
    from(w in Weather,
      where: w.zone_id == ^zone_id,
      order_by: [desc: w.started_at],
      limit: 1
    )
    |> Repo.one()
  end

  def create_weather(attrs \\ %{}) do
    %Weather{}
    |> Weather.changeset(attrs)
    |> Repo.insert()
  end

  def update_weather(%Weather{} = weather, attrs) do
    weather
    |> Weather.changeset(attrs)
    |> Repo.update()
  end

  def delete_weather(%Weather{} = weather) do
    Repo.delete(weather)
  end

  def get_active_weather_for_zone(zone_id) do
    now = DateTime.utc_now()

    from(w in Weather,
      where: w.zone_id == ^zone_id,
      where: fragment("? + INTERVAL '1 minute' * ?", w.started_at, w.duration_minutes) > ^now,
      order_by: [desc: w.started_at],
      limit: 1
    )
    |> Repo.one()
  end

  def cleanup_expired_weather do
    now = DateTime.utc_now()

    from(w in Weather,
      where: fragment("? + INTERVAL '1 minute' * ?", w.started_at, w.duration_minutes) <= ^now
    )
    |> Repo.delete_all()
  end

  def get_weather_effects_for_zone(zone_id) do
    case get_active_weather_for_zone(zone_id) do
      nil -> Weather.get_weather_effects("clear", 1)
      weather -> Weather.get_weather_effects(weather.weather_type, weather.intensity)
    end
  end

  def get_weather_description_for_zone(zone_id) do
    case get_active_weather_for_zone(zone_id) do
      nil -> Weather.weather_description("clear", 1)
      weather -> Weather.weather_description(weather.weather_type, weather.intensity)
    end
  end
end

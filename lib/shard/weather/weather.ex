defmodule Shard.Weather.Weather do
  @moduledoc """
  Weather schema and functions for managing weather conditions.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @weather_types [
    "clear",
    "cloudy", 
    "rainy",
    "stormy",
    "foggy",
    "snowy",
    "windy"
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "weather" do
    field :zone_id, :binary_id
    field :weather_type, :string
    field :intensity, :integer, default: 1  # 1-5 scale
    field :duration_minutes, :integer, default: 30
    field :started_at, :utc_datetime
    field :effects, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(weather, attrs) do
    weather
    |> cast(attrs, [:zone_id, :weather_type, :intensity, :duration_minutes, :started_at, :effects])
    |> validate_required([:zone_id, :weather_type, :intensity, :duration_minutes, :started_at])
    |> validate_inclusion(:weather_type, @weather_types)
    |> validate_number(:intensity, greater_than: 0, less_than_or_equal_to: 5)
    |> validate_number(:duration_minutes, greater_than: 0)
  end

  def weather_types, do: @weather_types

  def get_weather_effects(weather_type, intensity) do
    base_effects = case weather_type do
      "clear" -> %{visibility: 1.0, movement_speed: 1.0, combat_accuracy: 1.0}
      "cloudy" -> %{visibility: 0.9, movement_speed: 1.0, combat_accuracy: 0.95}
      "rainy" -> %{visibility: 0.7, movement_speed: 0.8, combat_accuracy: 0.85}
      "stormy" -> %{visibility: 0.5, movement_speed: 0.6, combat_accuracy: 0.7}
      "foggy" -> %{visibility: 0.3, movement_speed: 0.9, combat_accuracy: 0.6}
      "snowy" -> %{visibility: 0.6, movement_speed: 0.7, combat_accuracy: 0.8}
      "windy" -> %{visibility: 0.8, movement_speed: 1.1, combat_accuracy: 0.75}
      _ -> %{visibility: 1.0, movement_speed: 1.0, combat_accuracy: 1.0}
    end

    # Scale effects by intensity
    intensity_multiplier = intensity / 3.0
    
    %{
      visibility: max(0.1, base_effects.visibility * (2 - intensity_multiplier)),
      movement_speed: max(0.3, base_effects.movement_speed * (2 - intensity_multiplier)),
      combat_accuracy: max(0.4, base_effects.combat_accuracy * (2 - intensity_multiplier))
    }
  end

  def weather_description(weather_type, intensity) do
    intensity_desc = case intensity do
      1 -> "light"
      2 -> "moderate" 
      3 -> "heavy"
      4 -> "severe"
      5 -> "extreme"
    end

    case weather_type do
      "clear" -> "The sky is clear and bright"
      "cloudy" -> "#{String.capitalize(intensity_desc)} clouds cover the sky"
      "rainy" -> "#{String.capitalize(intensity_desc)} rain is falling"
      "stormy" -> "A #{intensity_desc} storm rages overhead"
      "foggy" -> "#{String.capitalize(intensity_desc)} fog obscures the area"
      "snowy" -> "#{String.capitalize(intensity_desc)} snow is falling"
      "windy" -> "#{String.capitalize(intensity_desc)} winds blow through the area"
      _ -> "The weather is unremarkable"
    end
  end
end

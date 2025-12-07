defmodule Shard.WorldTime.TimeCycle do
  @moduledoc """
  Schema for tracking the world's current time state.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "time_cycles" do
    field :current_minute, :integer, default: 0
    field :current_hour, :integer, default: 12
    field :current_day, :integer, default: 1
    field :time_multiplier, :float, default: 1.0  # How fast time passes relative to real time

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(time_cycle, attrs) do
    time_cycle
    |> cast(attrs, [:current_minute, :current_hour, :current_day, :time_multiplier])
    |> validate_required([:current_minute, :current_hour, :current_day])
    |> validate_number(:current_minute, greater_than_or_equal_to: 0, less_than: 60)
    |> validate_number(:current_hour, greater_than_or_equal_to: 0, less_than: 24)
    |> validate_number(:current_day, greater_than: 0)
    |> validate_number(:time_multiplier, greater_than: 0.0)
  end
end

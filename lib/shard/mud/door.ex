defmodule Shard.Mud.Door do
  use Ecto.Schema
  import Ecto.Changeset

  schema "doors" do
    field :is_open, :boolean, default: false
    field :is_locked, :boolean, default: false
    field :exit, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(door, attrs) do
    door
    |> cast(attrs, [:is_open, :is_locked, :exit])
    |> validate_required([:is_open, :is_locked, :exit])
  end
end

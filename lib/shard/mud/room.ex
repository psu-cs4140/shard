defmodule Shard.Mud.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :name, :string
    field :description, :string
    
    belongs_to :north_door, Shard.Mud.Door, foreign_key: :north_door_id
    belongs_to :east_door, Shard.Mud.Door, foreign_key: :east_door_id
    belongs_to :south_door, Shard.Mud.Door, foreign_key: :south_door_id
    belongs_to :west_door, Shard.Mud.Door, foreign_key: :west_door_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name, :description, :north_door_id, :east_door_id, :south_door_id, :west_door_id])
    |> validate_required([:name])
  end
end

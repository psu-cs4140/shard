defmodule Shard.Items.RoomItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Items.Item
  alias Shard.Characters.Character

  schema "room_items" do
    field :location, :string
    field :quantity, :integer, default: 1
    field :x_position, :decimal, default: Decimal.new("0.0")
    field :y_position, :decimal, default: Decimal.new("0.0")
    field :respawn_timer, :utc_datetime
    field :is_permanent, :boolean, default: false

    belongs_to :item, Item
    belongs_to :dropped_by_character, Character

    timestamps(type: :utc_datetime)
  end

  def changeset(room_item, attrs) do
    room_item
    |> cast(attrs, [
      :location, :item_id, :quantity, :x_position, :y_position,
      :dropped_by_character_id, :respawn_timer, :is_permanent
    ])
    |> validate_required([:location, :item_id, :quantity])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:x_position, greater_than_or_equal_to: 0)
    |> validate_number(:y_position, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:item_id)
    |> foreign_key_constraint(:dropped_by_character_id)
  end
end

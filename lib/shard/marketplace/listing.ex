defmodule Shard.Marketplace.Listing do
  @moduledoc """
  Schema for marketplace listings where players can sell equipment to other players.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Items.CharacterInventory
  alias Shard.Users.User

  @listing_statuses ["active", "sold", "cancelled"]

  def listing_statuses, do: @listing_statuses

  schema "marketplace_listings" do
    field :price, :integer
    field :status, :string, default: "active"
    field :sold_at, :utc_datetime
    field :cancelled_at, :utc_datetime

    belongs_to :seller, User
    belongs_to :buyer, User
    belongs_to :character_inventory, CharacterInventory

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(listing, attrs) do
    listing
    |> cast(attrs, [
      :price,
      :status,
      :sold_at,
      :cancelled_at,
      :seller_id,
      :buyer_id,
      :character_inventory_id
    ])
    |> validate_required([:price, :seller_id, :character_inventory_id])
    |> validate_number(:price, greater_than: 0)
    |> validate_inclusion(:status, @listing_statuses)
    |> foreign_key_constraint(:seller_id)
    |> foreign_key_constraint(:buyer_id)
    |> foreign_key_constraint(:character_inventory_id)
    |> validate_status_consistency()
  end

  defp validate_status_consistency(changeset) do
    status = get_field(changeset, :status)
    sold_at = get_field(changeset, :sold_at)
    cancelled_at = get_field(changeset, :cancelled_at)

    cond do
      status == "sold" && is_nil(sold_at) ->
        add_error(changeset, :sold_at, "must be set when status is sold")

      status == "cancelled" && is_nil(cancelled_at) ->
        add_error(changeset, :cancelled_at, "must be set when status is cancelled")

      status == "active" && (sold_at || cancelled_at) ->
        changeset
        |> put_change(:sold_at, nil)
        |> put_change(:cancelled_at, nil)

      true ->
        changeset
    end
  end
end

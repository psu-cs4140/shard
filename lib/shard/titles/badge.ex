defmodule Shard.Titles.Badge do
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Titles.CharacterBadge

  @categories ["achievement", "combat", "exploration", "economy", "social", "gambling", "special"]
  @rarities ["common", "uncommon", "rare", "epic", "legendary"]

  schema "badges" do
    field :name, :string
    field :description, :string
    field :category, :string
    field :rarity, :string
    field :icon, :string
    field :requirements, :map, default: %{}
    field :is_active, :boolean, default: true
    field :color, :string

    has_many :character_badges, CharacterBadge

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(badge, attrs) do
    badge
    |> cast(attrs, [:name, :description, :category, :rarity, :icon, :requirements, :is_active, :color])
    |> validate_required([:name, :description, :category, :rarity])
    |> validate_inclusion(:category, @categories)
    |> validate_inclusion(:rarity, @rarities)
    |> validate_length(:name, min: 1, max: 50)
    |> validate_length(:description, min: 1, max: 200)
    |> validate_length(:icon, max: 10)
    |> unique_constraint(:name)
  end

  @doc """
  Returns available categories for badges.
  """
  def categories, do: @categories

  @doc """
  Returns available rarities for badges.
  """
  def rarities, do: @rarities

  @doc """
  Gets the color class for a badge based on rarity.
  """
  def get_color_class(%__MODULE__{} = badge) do
    badge.color || get_default_color(badge.rarity)
  end

  defp get_default_color("common"), do: "text-gray-600"
  defp get_default_color("uncommon"), do: "text-green-600"
  defp get_default_color("rare"), do: "text-blue-600"
  defp get_default_color("epic"), do: "text-purple-600"
  defp get_default_color("legendary"), do: "text-yellow-600"
end

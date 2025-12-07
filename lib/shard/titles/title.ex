defmodule Shard.Titles.Title do
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Titles.CharacterTitle

  @categories ["progression", "combat", "exploration", "economy", "social", "achievement", "special"]
  @rarities ["common", "uncommon", "rare", "epic", "legendary"]

  schema "titles" do
    field :name, :string
    field :description, :string
    field :category, :string
    field :rarity, :string
    field :requirements, :map, default: %{}
    field :is_active, :boolean, default: true
    field :color, :string
    field :prefix, :boolean, default: false  # true if title goes before name, false if after

    has_many :character_titles, CharacterTitle

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(title, attrs) do
    title
    |> cast(attrs, [:name, :description, :category, :rarity, :requirements, :is_active, :color, :prefix])
    |> validate_required([:name, :description, :category, :rarity])
    |> validate_inclusion(:category, @categories)
    |> validate_inclusion(:rarity, @rarities)
    |> validate_length(:name, min: 1, max: 50)
    |> validate_length(:description, min: 1, max: 200)
    |> unique_constraint(:name)
  end

  @doc """
  Returns available categories for titles.
  """
  def categories, do: @categories

  @doc """
  Returns available rarities for titles.
  """
  def rarities, do: @rarities

  @doc """
  Formats a title for display with a character name.
  """
  def format_with_name(%__MODULE__{} = title, character_name) do
    if title.prefix do
      "#{title.name} #{character_name}"
    else
      "#{character_name} the #{title.name}"
    end
  end

  @doc """
  Gets the color class for a title based on rarity.
  """
  def get_color_class(%__MODULE__{} = title) do
    title.color || get_default_color(title.rarity)
  end

  defp get_default_color("common"), do: "text-gray-600"
  defp get_default_color("uncommon"), do: "text-green-600"
  defp get_default_color("rare"), do: "text-blue-600"
  defp get_default_color("epic"), do: "text-purple-600"
  defp get_default_color("legendary"), do: "text-yellow-600"
end

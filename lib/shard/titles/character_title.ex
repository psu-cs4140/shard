defmodule Shard.Titles.CharacterTitle do
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Characters.Character
  alias Shard.Titles.Title

  schema "character_titles" do
    field :earned_at, :utc_datetime
    field :is_active, :boolean, default: false

    belongs_to :character, Character
    belongs_to :title, Title

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(character_title, attrs) do
    character_title
    |> cast(attrs, [:character_id, :title_id, :earned_at, :is_active])
    |> validate_required([:character_id, :title_id, :earned_at])
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:title_id)
    |> unique_constraint([:character_id, :title_id])
  end
end

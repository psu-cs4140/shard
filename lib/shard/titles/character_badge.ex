defmodule Shard.Titles.CharacterBadge do
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Characters.Character
  alias Shard.Titles.Badge

  schema "character_badges" do
    field :earned_at, :utc_datetime
    field :is_active, :boolean, default: false
    field :display_order, :integer  # 1, 2, or 3 for active badges

    belongs_to :character, Character
    belongs_to :badge, Badge

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(character_badge, attrs) do
    character_badge
    |> cast(attrs, [:character_id, :badge_id, :earned_at, :is_active, :display_order])
    |> validate_required([:character_id, :badge_id, :earned_at])
    |> validate_inclusion(:display_order, [1, 2, 3])
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:badge_id)
    |> unique_constraint([:character_id, :badge_id])
  end
end

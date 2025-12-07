defmodule Shard.Titles do
  @moduledoc """
  The Titles context for managing character titles and badges.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo

  alias Shard.Titles.{Title, Badge, CharacterTitle, CharacterBadge}

  ## Titles

  @doc """
  Returns the list of titles.
  """
  def list_titles do
    Repo.all(Title)
  end

  @doc """
  Gets a single title.
  """
  def get_title!(id), do: Repo.get!(Title, id)

  @doc """
  Creates a title.
  """
  def create_title(attrs \\ %{}) do
    %Title{}
    |> Title.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a title.
  """
  def update_title(%Title{} = title, attrs) do
    title
    |> Title.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a title.
  """
  def delete_title(%Title{} = title) do
    Repo.delete(title)
  end

  ## Badges

  @doc """
  Returns the list of badges.
  """
  def list_badges do
    Repo.all(Badge)
  end

  @doc """
  Gets a single badge.
  """
  def get_badge!(id), do: Repo.get!(Badge, id)

  @doc """
  Creates a badge.
  """
  def create_badge(attrs \\ %{}) do
    %Badge{}
    |> Badge.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a badge.
  """
  def update_badge(%Badge{} = badge, attrs) do
    badge
    |> Badge.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a badge.
  """
  def delete_badge(%Badge{} = badge) do
    Repo.delete(badge)
  end

  ## Character Titles

  @doc """
  Gets all titles for a character.
  """
  def get_character_titles(character_id) do
    from(ct in CharacterTitle,
      join: t in Title,
      on: ct.title_id == t.id,
      where: ct.character_id == ^character_id,
      select: {ct, t},
      order_by: [desc: ct.earned_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets the active title for a character.
  """
  def get_active_title(character_id) do
    from(ct in CharacterTitle,
      join: t in Title,
      on: ct.title_id == t.id,
      where: ct.character_id == ^character_id and ct.is_active == true,
      select: t
    )
    |> Repo.one()
  end

  @doc """
  Awards a title to a character.
  """
  def award_title(character_id, title_id) do
    # Check if character already has this title
    existing = Repo.get_by(CharacterTitle, character_id: character_id, title_id: title_id)

    case existing do
      nil ->
        %CharacterTitle{}
        |> CharacterTitle.changeset(%{
          character_id: character_id,
          title_id: title_id,
          earned_at: DateTime.utc_now()
        })
        |> Repo.insert()

      existing ->
        {:ok, existing}
    end
  end

  @doc """
  Sets a title as active for a character.
  """
  def set_active_title(character_id, title_id) do
    # First check if character has this title
    character_title = Repo.get_by(CharacterTitle, character_id: character_id, title_id: title_id)

    case character_title do
      nil ->
        {:error, :title_not_owned}

      _ ->
        # Deactivate all current titles
        from(ct in CharacterTitle,
          where: ct.character_id == ^character_id
        )
        |> Repo.update_all(set: [is_active: false])

        # Activate the selected title
        character_title
        |> CharacterTitle.changeset(%{is_active: true})
        |> Repo.update()
    end
  end

  @doc """
  Removes active title from a character.
  """
  def remove_active_title(character_id) do
    from(ct in CharacterTitle,
      where: ct.character_id == ^character_id
    )
    |> Repo.update_all(set: [is_active: false])

    {:ok, :title_removed}
  end

  ## Character Badges

  @doc """
  Gets all badges for a character.
  """
  def get_character_badges(character_id) do
    from(cb in CharacterBadge,
      join: b in Badge,
      on: cb.badge_id == b.id,
      where: cb.character_id == ^character_id,
      select: {cb, b},
      order_by: [desc: cb.earned_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets the active badges for a character (up to 3).
  """
  def get_active_badges(character_id) do
    from(cb in CharacterBadge,
      join: b in Badge,
      on: cb.badge_id == b.id,
      where: cb.character_id == ^character_id and cb.is_active == true,
      select: b,
      order_by: [asc: cb.display_order],
      limit: 3
    )
    |> Repo.all()
  end

  @doc """
  Awards a badge to a character.
  """
  def award_badge(character_id, badge_id) do
    # Check if character already has this badge
    existing = Repo.get_by(CharacterBadge, character_id: character_id, badge_id: badge_id)

    case existing do
      nil ->
        %CharacterBadge{}
        |> CharacterBadge.changeset(%{
          character_id: character_id,
          badge_id: badge_id,
          earned_at: DateTime.utc_now()
        })
        |> Repo.insert()

      existing ->
        {:ok, existing}
    end
  end

  @doc """
  Sets badges as active for a character (up to 3).
  """
  def set_active_badges(character_id, badge_ids) when length(badge_ids) <= 3 do
    # Verify character owns all badges
    owned_badges = 
      from(cb in CharacterBadge,
        where: cb.character_id == ^character_id and cb.badge_id in ^badge_ids,
        select: cb.badge_id
      )
      |> Repo.all()

    if length(owned_badges) == length(badge_ids) do
      # Deactivate all current badges
      from(cb in CharacterBadge,
        where: cb.character_id == ^character_id
      )
      |> Repo.update_all(set: [is_active: false, display_order: nil])

      # Activate selected badges with display order
      badge_ids
      |> Enum.with_index(1)
      |> Enum.each(fn {badge_id, order} ->
        from(cb in CharacterBadge,
          where: cb.character_id == ^character_id and cb.badge_id == ^badge_id
        )
        |> Repo.update_all(set: [is_active: true, display_order: order])
      end)

      {:ok, :badges_updated}
    else
      {:error, :badges_not_owned}
    end
  end

  def set_active_badges(_character_id, badge_ids) when length(badge_ids) > 3 do
    {:error, :too_many_badges}
  end

  @doc """
  Removes all active badges from a character.
  """
  def remove_active_badges(character_id) do
    from(cb in CharacterBadge,
      where: cb.character_id == ^character_id
    )
    |> Repo.update_all(set: [is_active: false, display_order: nil])

    {:ok, :badges_removed}
  end

  ## Utility Functions

  @doc """
  Checks if a character has a specific title.
  """
  def character_has_title?(character_id, title_id) do
    Repo.exists?(
      from ct in CharacterTitle,
        where: ct.character_id == ^character_id and ct.title_id == ^title_id
    )
  end

  @doc """
  Checks if a character has a specific badge.
  """
  def character_has_badge?(character_id, badge_id) do
    Repo.exists?(
      from cb in CharacterBadge,
        where: cb.character_id == ^character_id and cb.badge_id == ^badge_id
    )
  end

  @doc """
  Gets titles by category.
  """
  def get_titles_by_category(category) do
    from(t in Title,
      where: t.category == ^category and t.is_active == true,
      order_by: [asc: t.name]
    )
    |> Repo.all()
  end

  @doc """
  Gets badges by category.
  """
  def get_badges_by_category(category) do
    from(b in Badge,
      where: b.category == ^category and b.is_active == true,
      order_by: [asc: b.name]
    )
    |> Repo.all()
  end

  @doc """
  Creates default titles and badges for the system.
  """
  def create_default_titles_and_badges do
    # Create default titles
    default_titles = [
      %{name: "Novice", description: "A new adventurer", category: "progression", rarity: "common", requirements: %{level: 1}},
      %{name: "Warrior", description: "A seasoned fighter", category: "combat", rarity: "uncommon", requirements: %{kills: 100}},
      %{name: "Champion", description: "A legendary hero", category: "combat", rarity: "epic", requirements: %{boss_kills: 10}},
      %{name: "Explorer", description: "Has seen many lands", category: "exploration", rarity: "uncommon", requirements: %{zones_visited: 5}},
      %{name: "Merchant", description: "Master of trade", category: "economy", rarity: "rare", requirements: %{gold_earned: 10000}},
      %{name: "The Wealthy", description: "Swimming in gold", category: "economy", rarity: "legendary", requirements: %{gold_owned: 100000}}
    ]

    # Create default badges
    default_badges = [
      %{name: "First Steps", description: "Created your first character", category: "achievement", rarity: "common", icon: "🎯"},
      %{name: "Monster Slayer", description: "Defeated 50 monsters", category: "combat", rarity: "uncommon", icon: "⚔️"},
      %{name: "Boss Hunter", description: "Defeated a boss", category: "combat", rarity: "rare", icon: "👑"},
      %{name: "Treasure Hunter", description: "Found 10 treasure chests", category: "exploration", rarity: "uncommon", icon: "💎"},
      %{name: "Social Butterfly", description: "Made 5 friends", category: "social", rarity: "uncommon", icon: "🦋"},
      %{name: "Lucky", description: "Won 10 coin flips", category: "gambling", rarity: "rare", icon: "🍀"}
    ]

    title_results = Enum.map(default_titles, &create_title/1)
    badge_results = Enum.map(default_badges, &create_badge/1)

    {:ok, %{titles: title_results, badges: badge_results}}
  end
end

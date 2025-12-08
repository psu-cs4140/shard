defmodule Shard.Achievements do
  @moduledoc """
  The Achievements context - manages achievements and user progress.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo

  alias Shard.Achievements.{Achievement, UserAchievement}
  alias Shard.Users.User

  @doc """
  Returns the list of achievements.

  ## Examples

      iex> list_achievements()
      [%Achievement{}, ...]

  """
  def list_achievements do
    Repo.all(Achievement)
  end

  @doc """
  Gets a single achievement.

  Raises `Ecto.NoResultsError` if the Achievement does not exist.

  ## Examples

      iex> get_achievement!(123)
      %Achievement{}

      iex> get_achievement!(456)
      ** (Ecto.NoResultsError)

  """
  def get_achievement!(id), do: Repo.get!(Achievement, id)

  @doc """
  Creates an achievement.

  ## Examples

      iex> create_achievement(%{field: value})
      {:ok, %Achievement{}}

      iex> create_achievement(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_achievement(attrs \\ %{}) do
    %Achievement{}
    |> Achievement.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an achievement.

  ## Examples

      iex> update_achievement(achievement, %{field: new_value})
      {:ok, %Achievement{}}

      iex> update_achievement(achievement, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_achievement(%Achievement{} = achievement, attrs) do
    achievement
    |> Achievement.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an achievement.

  ## Examples

      iex> delete_achievement(achievement)
      {:ok, %Achievement{}}

      iex> delete_achievement(achievement)
      {:error, %Ecto.Changeset{}}

  """
  def delete_achievement(%Achievement{} = achievement) do
    Repo.delete(achievement)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking achievement changes.

  ## Examples

      iex> change_achievement(achievement)
      %Ecto.Changeset{data: %Achievement{}}

  """
  def change_achievement(%Achievement{} = achievement, attrs \\ %{}) do
    Achievement.changeset(achievement, attrs)
  end

  @doc """
  Gets all achievements earned by a user.
  """
  def get_user_achievements(%User{} = user) do
    query =
      from ua in UserAchievement,
        where: ua.user_id == ^user.id,
        join: a in Achievement,
        on: ua.achievement_id == a.id,
        select: {ua, a},
        order_by: [desc: ua.earned_at]

    Repo.all(query)
  end

  @doc """
  Awards an achievement to a user.
  """
  def award_achievement(%User{} = user, %Achievement{} = achievement) do
    case %UserAchievement{}
         |> UserAchievement.changeset(%{
           user_id: user.id,
           achievement_id: achievement.id,
           earned_at: DateTime.utc_now()
         })
         |> Repo.insert() do
      {:ok, user_achievement} ->
        # Trigger achievement notification sound
        trigger_achievement_notification(user.id, achievement)
        {:ok, user_achievement}

      error ->
        error
    end
  end

  @doc """
  Checks if a user has earned a specific achievement.
  """
  def has_achievement?(%User{} = user, %Achievement{} = achievement) do
    query =
      from ua in UserAchievement,
        where: ua.user_id == ^user.id and ua.achievement_id == ^achievement.id

    Repo.exists?(query)
  end

  @doc """
  Gets achievement statistics for a user.
  """
  def get_user_achievement_stats(%User{} = user) do
    total_achievements = Repo.aggregate(Achievement, :count, :id)

    earned_achievements =
      from(ua in UserAchievement, where: ua.user_id == ^user.id)
      |> Repo.aggregate(:count, :id)

    total_points =
      from(ua in UserAchievement,
        where: ua.user_id == ^user.id,
        join: a in Achievement,
        on: ua.achievement_id == a.id,
        select: sum(a.points)
      )
      |> Repo.one() || 0

    %{
      total_achievements: total_achievements,
      earned_achievements: earned_achievements,
      total_points: total_points,
      completion_percentage:
        if(total_achievements > 0,
          do: Float.round(earned_achievements / total_achievements * 100, 1),
          else: 0.0
        )
    }
  end

  @doc """
  Checks and awards quest completion achievements for a user.
  This should be called when a user completes a quest.
  """
  def check_quest_completion_achievements(%User{} = user, quest_title) do
    # Find achievements that require this quest to be completed
    quest_achievements =
      from(a in Achievement,
        where: fragment("?->>'type' = 'quest_completed'", a.requirements),
        where: fragment("?->>'quest' = ?", a.requirements, ^quest_title)
      )
      |> Repo.all()

    # Award each achievement if the user doesn't already have it
    Enum.each(quest_achievements, fn achievement ->
      unless has_achievement?(user, achievement) do
        case award_achievement(user, achievement) do
          {:ok, _user_achievement} ->
            # Achievement awarded successfully
            :ok

          {:error, _changeset} ->
            # Achievement already exists or other error
            :ok
        end
      end
    end)
  end

  @doc """
  Checks and awards zone entry achievements for a user.
  This should be called when a user enters a zone.
  """
  def check_zone_entry_achievements(user_id, zone_name) do
    # Debug logging to see what zone names we're getting
    require Logger
    Logger.info("Checking zone entry achievement for user #{user_id}, zone: '#{zone_name}'")
    
    case zone_name do
      "Beginner Bone Zone" ->
        Logger.info("Awarding Beginner Bone Zone achievement")
        award_achievement_by_name(user_id, "Enter Beginner Bone Zone")

      "Vampire's Manor" ->
        Logger.info("Awarding Vampire Manor achievement")
        award_achievement_by_name(user_id, "Enter Vampire Manor")

      "Mines" ->
        Logger.info("Awarding Mines achievement")
        award_achievement_by_name(user_id, "Enter Mines")

      "Whispering Forest" ->
        Logger.info("Awarding Whispering Forest achievement")
        award_achievement_by_name(user_id, "Enter Whispering Forest")

      _ ->
        Logger.info("No achievement found for zone: '#{zone_name}'")
        {:ok, :no_achievement}
    end
  end

  @doc """
  Awards an achievement to a user by achievement name.
  """
  def award_achievement_by_name(user_id, achievement_name) do
    case get_achievement_by_name(achievement_name) do
      nil -> {:error, :achievement_not_found}
      achievement -> handle_achievement_award(user_id, achievement_name, achievement)
    end
  end

  defp handle_achievement_award(user_id, achievement_name, achievement) do
    if user_has_achievement?(user_id, achievement_name) do
      {:ok, :already_earned}
    else
      create_user_achievement(user_id, achievement)
    end
  end

  defp create_user_achievement(user_id, achievement) do
    case %UserAchievement{}
         |> UserAchievement.changeset(%{
           user_id: user_id,
           achievement_id: achievement.id,
           earned_at: DateTime.utc_now(),
           progress: %{}
         })
         |> Repo.insert() do
      {:ok, user_achievement} ->
        trigger_achievement_notification(user_id, achievement)
        {:ok, user_achievement}

      error ->
        error
    end
  end

  @doc """
  Gets an achievement by name.
  """
  def get_achievement_by_name(name) do
    Repo.get_by(Achievement, name: name)
  end

  @doc """
  Checks if a user has earned a specific achievement by name.
  """
  def user_has_achievement?(user_id, achievement_name) do
    from(ua in UserAchievement,
      join: a in Achievement,
      on: ua.achievement_id == a.id,
      where: ua.user_id == ^user_id and a.name == ^achievement_name
    )
    |> Repo.exists?()
  end

  @doc """
  Checks and awards mining resource achievements for a user.
  This should be called when a user obtains mining resources.
  """
  def check_mining_resource_achievements(user_id, resources) do
    # Check for first gem achievement
    if Map.get(resources, :gem, 0) > 0 do
      award_achievement_by_name(user_id, "GEMS!")
    end

    # Check for first stone achievement
    if Map.get(resources, :stone, 0) > 0 do
      award_achievement_by_name(user_id, "Entering the Stone Age")
    end

    :ok
  end

  @doc """
  Checks and awards chopping resource achievements for a user.
  This should be called when a user obtains chopping resources.
  """
  def check_chopping_resource_achievements(user_id, resources) do
    # Check for first wood achievement
    if Map.get(resources, :wood, 0) > 0 do
      award_achievement_by_name(user_id, "Acquiring Lumber")
    end

    # Check for first resin achievement
    if Map.get(resources, :resin, 0) > 0 do
      award_achievement_by_name(user_id, "A Hint of Prehistoric Life")
    end

    :ok
  end

  @doc """
  Checks and awards gambling achievements for a user.
  This should be called when a user wins or loses a bet.
  """
  def check_gambling_achievements(user_id, result) do
    case result do
      :won ->
        award_achievement_by_name(user_id, "Lucky Gambler")

      :lost ->
        award_achievement_by_name(user_id, "Learning Experience")

      _ ->
        :ok
    end
  end

  @doc """
  Triggers an achievement notification sound for a user.
  This function can be extended to send real-time notifications to the frontend.
  """
  def trigger_achievement_notification(user_id, achievement) do
    # For now, this is a placeholder that could be extended to:
    # 1. Send a Phoenix PubSub message to the user's LiveView
    # 2. Trigger a sound notification in the frontend
    # 3. Show a popup notification

    Phoenix.PubSub.broadcast(
      Shard.PubSub,
      "user:#{user_id}",
      {:achievement_unlocked,
       %{
         achievement: achievement,
         sound: true,
         timestamp: DateTime.utc_now()
       }}
    )
  end
end

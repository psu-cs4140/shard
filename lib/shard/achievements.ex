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
    query = from ua in UserAchievement,
      where: ua.user_id == ^user.id,
      join: a in Achievement, on: ua.achievement_id == a.id,
      select: {ua, a},
      order_by: [desc: ua.earned_at]

    Repo.all(query)
  end

  @doc """
  Awards an achievement to a user.
  """
  def award_achievement(%User{} = user, %Achievement{} = achievement) do
    %UserAchievement{}
    |> UserAchievement.changeset(%{
      user_id: user.id,
      achievement_id: achievement.id,
      earned_at: DateTime.utc_now()
    })
    |> Repo.insert()
  end

  @doc """
  Checks if a user has earned a specific achievement.
  """
  def has_achievement?(%User{} = user, %Achievement{} = achievement) do
    query = from ua in UserAchievement,
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
        join: a in Achievement, on: ua.achievement_id == a.id,
        select: sum(a.points))
      |> Repo.one() || 0

    %{
      total_achievements: total_achievements,
      earned_achievements: earned_achievements,
      total_points: total_points,
      completion_percentage: if(total_achievements > 0, do: Float.round(earned_achievements / total_achievements * 100, 1), else: 0.0)
    }
  end
end

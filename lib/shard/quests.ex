defmodule Shard.Quests do
  @moduledoc """
  The Quests context.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo

  alias Shard.Quests.{Quest, QuestAcceptance}
  alias Shard.Users.User

  @doc """
  Returns the list of quests.

  ## Examples

      iex> list_quests()
      [%Quest{}, ...]

  """
  def list_quests do
    Repo.all(Quest)
  end

  @doc """
  Returns the list of quests with preloaded associations.
  """
  def list_quests_with_preloads do
    Repo.all(Quest)
    |> Repo.preload([:giver_npc, :turn_in_npc])
  end

  @doc """
  Gets a single quest.

  Raises `Ecto.NoResultsError` if the Quest does not exist.

  ## Examples

      iex> get_quest!(123)
      %Quest{}

      iex> get_quest!(456)
      ** (Ecto.NoResultsError)

  """
  def get_quest!(id), do: Repo.get!(Quest, id)

  @doc """
  Gets a single quest with preloaded associations.
  """
  def get_quest_with_preloads!(id) do
    Repo.get!(Quest, id)
    |> Repo.preload([:giver_npc, :turn_in_npc])
  end

  @doc """
  Gets quests by type.
  """
  def get_quests_by_type(quest_type) do
    from(q in Quest, where: q.quest_type == ^quest_type and q.is_active == true)
    |> Repo.all()
  end

  @doc """
  Gets quests by difficulty.
  """
  def get_quests_by_difficulty(difficulty) do
    from(q in Quest, where: q.difficulty == ^difficulty and q.is_active == true)
    |> Repo.all()
  end

  @doc """
  Gets quests by status.
  """
  def get_quests_by_status(status) do
    from(q in Quest, where: q.status == ^status and q.is_active == true)
    |> Repo.all()
  end

  @doc """
  Gets available quests for a given level.
  """
  def get_available_quests_for_level(level) do
    from(q in Quest, 
      where: q.status == "available" and 
             q.is_active == true and 
             q.min_level <= ^level and 
             (is_nil(q.max_level) or q.max_level >= ^level))
    |> Repo.all()
  end

  @doc """
  Checks if a user has already accepted a specific quest.

  ## Examples

      iex> quest_accepted_by_user?(user_id, quest_id)
      true

      iex> quest_accepted_by_user?(user_id, quest_id)
      false

  """
  def quest_accepted_by_user?(user_id, quest_id) do
    from(qa in QuestAcceptance,
      where: qa.user_id == ^user_id and qa.quest_id == ^quest_id)
    |> Repo.exists?()
  end

  @doc """
  Checks if a user has already accepted or is in progress on a specific quest.

  ## Examples

      iex> quest_in_progress_by_user?(user_id, quest_id)
      true

      iex> quest_in_progress_by_user?(user_id, quest_id)
      false

  """
  def quest_in_progress_by_user?(user_id, quest_id) do
    from(qa in QuestAcceptance,
      where: qa.user_id == ^user_id and qa.quest_id == ^quest_id and qa.status in ["accepted", "in_progress"])
    |> Repo.exists?()
  end

  @doc """
  Checks if a user has already completed a specific quest.

  ## Examples

      iex> quest_completed_by_user?(user_id, quest_id)
      true

      iex> quest_completed_by_user?(user_id, quest_id)
      false

  """
  def quest_completed_by_user?(user_id, quest_id) do
    from(qa in QuestAcceptance,
      where: qa.user_id == ^user_id and qa.quest_id == ^quest_id and qa.status == "completed")
    |> Repo.exists?()
  end

  @doc """
  Checks if a user has ever accepted a quest (regardless of current status).

  ## Examples

      iex> quest_ever_accepted_by_user?(user_id, quest_id)
      true

      iex> quest_ever_accepted_by_user?(user_id, quest_id)
      false

  """
  def quest_ever_accepted_by_user?(user_id, quest_id) do
    from(qa in QuestAcceptance,
      where: qa.user_id == ^user_id and qa.quest_id == ^quest_id)
    |> Repo.exists?()
  end

  @doc """
  Accepts a quest for a user.

  ## Examples

      iex> accept_quest(user_id, quest_id)
      {:ok, %QuestAcceptance{}}

      iex> accept_quest(user_id, quest_id)
      {:error, %Ecto.Changeset{}}

  """
  def accept_quest(user_id, quest_id) do
    # Check if the user has already completed this quest
    if quest_completed_by_user?(user_id, quest_id) do
      {:error, :quest_already_completed}
    else
      %QuestAcceptance{}
      |> QuestAcceptance.accept_changeset(%{user_id: user_id, quest_id: quest_id})
      |> Repo.insert()
    end
  end

  @doc """
  Completes a quest for a user.

  ## Examples

      iex> complete_quest(user_id, quest_id)
      {:ok, %QuestAcceptance{}}

      iex> complete_quest(user_id, quest_id)
      {:error, %Ecto.Changeset{}}

  """
  def complete_quest(user_id, quest_id) do
    case from(qa in QuestAcceptance,
      where: qa.user_id == ^user_id and qa.quest_id == ^quest_id and qa.status in ["accepted", "in_progress"])
    |> Repo.one() do
      nil -> {:error, :quest_not_found}
      quest_acceptance ->
        quest_acceptance
        |> QuestAcceptance.changeset(%{status: "completed"})
        |> Repo.update()
    end
  end

  @doc """
  Gets all quest acceptances for a user.

  ## Examples

      iex> get_user_quest_acceptances(user_id)
      [%QuestAcceptance{}, ...]

  """
  def get_user_quest_acceptances(user_id) do
    from(qa in QuestAcceptance,
      where: qa.user_id == ^user_id,
      preload: [:quest])
    |> Repo.all()
  end

  @doc """
  Gets all active (accepted/in_progress) quest acceptances for a user.

  ## Examples

      iex> get_user_active_quests(user_id)
      [%QuestAcceptance{}, ...]

  """
  def get_user_active_quests(user_id) do
    from(qa in QuestAcceptance,
      where: qa.user_id == ^user_id and qa.status in ["accepted", "in_progress"],
      preload: [:quest])
    |> Repo.all()
  end

  @doc """
  Gets quests available to a user (not yet accepted).

  ## Examples

      iex> get_available_quests_for_user(user_id)
      [%Quest{}, ...]

  """
  def get_available_quests_for_user(user_id) do
    accepted_quest_ids = from(qa in QuestAcceptance,
      where: qa.user_id == ^user_id,
      select: qa.quest_id)

    from(q in Quest,
      where: q.is_active == true and q.id not in subquery(accepted_quest_ids))
    |> Repo.all()
  end

  @doc """
  Gets quests by giver NPC that are available to a user.

  ## Examples

      iex> get_available_quests_by_giver(user_id, npc_id)
      [%Quest{}, ...]

  """
  def get_available_quests_by_giver(user_id, npc_id) do
    accepted_quest_ids = from(qa in QuestAcceptance,
      where: qa.user_id == ^user_id,
      select: qa.quest_id)

    from(q in Quest,
      where: q.giver_npc_id == ^npc_id and 
             q.is_active == true and 
             q.status == "available" and
             q.id not in subquery(accepted_quest_ids),
      order_by: [asc: q.sort_order, asc: q.id])
    |> Repo.all()
  end

  @doc """
  Gets quests by giver NPC that are available to a user and haven't been completed.
  This excludes quests that have been completed to prevent repetition.

  ## Examples

      iex> get_available_quests_by_giver_excluding_completed(user_id, npc_id)
      [%Quest{}, ...]

  """
  def get_available_quests_by_giver_excluding_completed(user_id, npc_id) do
    # Get all quest IDs that the user has ever accepted (including completed ones)
    ever_accepted_quest_ids = from(qa in QuestAcceptance,
      where: qa.user_id == ^user_id,
      select: qa.quest_id)

    from(q in Quest,
      where: q.giver_npc_id == ^npc_id and 
             q.is_active == true and 
             q.status == "available" and
             q.id not in subquery(ever_accepted_quest_ids),
      order_by: [asc: q.sort_order, asc: q.id])
    |> Repo.all()
  end

  @doc """
  Creates a quest.

  ## Examples

      iex> create_quest(%{field: value})
      {:ok, %Quest{}}

      iex> create_quest(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_quest(attrs \\ %{}) do
    %Quest{}
    |> Quest.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a quest.

  ## Examples

      iex> update_quest(quest, %{field: new_value})
      {:ok, %Quest{}}

      iex> update_quest(quest, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_quest(%Quest{} = quest, attrs) do
    quest
    |> Quest.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a quest.

  ## Examples

      iex> delete_quest(quest)
      {:ok, %Quest{}}

      iex> delete_quest(quest)
      {:error, %Ecto.Changeset{}}

  """
  def delete_quest(%Quest{} = quest) do
    Repo.delete(quest)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking quest changes.

  ## Examples

      iex> change_quest(quest)
      %Ecto.Changeset{data: %Quest{}}

  """
  def change_quest(%Quest{} = quest, attrs \\ %{}) do
    Quest.changeset(quest, attrs)
  end
end

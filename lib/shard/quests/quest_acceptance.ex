defmodule Shard.Quests.QuestAcceptance do
  @moduledoc """
  This module defines the quest acceptance schema and includes
  functions determining if a quest it accepted or not
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Users.User
  alias Shard.Quests.Quest

  schema "quest_acceptances" do
    field :status, :string, default: "accepted"
    field :accepted_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :progress, :map, default: %{}

    belongs_to :user, User
    belongs_to :quest, Quest

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quest_acceptance, attrs) do
    quest_acceptance
    |> cast(attrs, [:user_id, :quest_id, :status, :accepted_at, :completed_at, :progress])
    |> validate_required([:user_id, :quest_id, :status, :accepted_at])
    |> validate_inclusion(:status, ["accepted", "in_progress", "completed", "failed", "abandoned"])
    |> unique_constraint([:user_id, :quest_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:quest_id)
  end

  def accept_changeset(quest_acceptance, attrs) do
    quest_acceptance
    |> cast(attrs, [:user_id, :quest_id])
    |> validate_required([:user_id, :quest_id])
    |> put_change(:status, "accepted")
    |> put_change(:accepted_at, DateTime.utc_now() |> DateTime.truncate(:second))
    |> validate_quest_not_in_progress()
    |> unique_constraint([:user_id, :quest_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:quest_id)
  end

  defp validate_quest_not_in_progress(changeset) do
    user_id = get_field(changeset, :user_id)
    quest_id = get_field(changeset, :quest_id)

    changeset =
      if user_id && quest_id && Shard.Quests.quest_in_progress_by_user?(user_id, quest_id) do
        add_error(changeset, :quest_id, "quest is already accepted or in progress")
      else
        changeset
      end

    # Also validate that user doesn't have another active quest of the same type
    validate_no_active_quest_of_same_type(changeset)
  end

  defp validate_no_active_quest_of_same_type(changeset) do
    user_id = get_field(changeset, :user_id)
    quest_id = get_field(changeset, :quest_id)

    # Early return if missing required fields
    unless user_id && quest_id do
      changeset
    else
      # Get the quest to check its type
      case Shard.Repo.get(Shard.Quests.Quest, quest_id) do
        nil -> changeset
        quest -> validate_quest_type_conflict(changeset, user_id, quest)
      end
    end
  end

  defp validate_quest_type_conflict(changeset, user_id, quest) do
    if Shard.Quests.user_has_active_quest_of_type?(user_id, quest.quest_type) do
      add_error(
        changeset,
        :quest_id,
        "you already have an active quest of type '#{quest.quest_type}'"
      )
    else
      changeset
    end
  end
end

defmodule Shard.Quests.QuestAcceptance do
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
    |> put_change(:accepted_at, DateTime.utc_now())
    |> unique_constraint([:user_id, :quest_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:quest_id)
  end
end

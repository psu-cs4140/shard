defmodule Shard.Social.ConversationParticipant do
  @moduledoc """
  Creates the schema for a conversation participant, basically who is in a conversation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Social.Conversation
  alias Shard.Users.User

  schema "conversation_participants" do
    belongs_to :conversation, Conversation
    belongs_to :user, User
    field :last_read_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [:conversation_id, :user_id, :last_read_at])
    |> validate_required([:conversation_id, :user_id])
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:conversation_id, :user_id])
  end
end

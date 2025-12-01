defmodule Shard.Social.Conversation do
  @moduledoc """
  Creates the schema for a conversation. A conversation includes many participants and messages.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Social.{ConversationParticipant, Message}

  schema "conversations" do
    field :name, :string
    field :type, :string, default: "direct"
    has_many :conversation_participants, ConversationParticipant
    has_many :participants, through: [:conversation_participants, :user]
    has_many :messages, Message

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:name, :type])
    |> validate_inclusion(:type, ["direct", "group"])
  end
end

defmodule Shard.Social.Message do
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Users.User
  alias Shard.Social.Conversation

  schema "messages" do
    field :content, :string
    belongs_to :conversation, Conversation
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :conversation_id, :user_id])
    |> validate_required([:content, :conversation_id, :user_id])
    |> validate_length(:content, min: 1, max: 1000)
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:user_id)
  end
end

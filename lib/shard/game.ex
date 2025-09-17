defmodule Shard.Game do
  import Ecto.Query
  import Ecto.Changeset, only: [change: 2]
  alias Shard.Repo
  alias Shard.Game.Character
  alias Shard.World
  alias Shard.World.Room

  def get_or_create_demo_character() do
    Repo.get_by(Character, name: "Demo") ||
      %Character{}
      |> Character.changeset(%{name: "Demo", current_room_id: first_room_id()})
      |> Repo.insert!()
  end

  def move(%Character{} = ch, dir) when is_binary(dir) do
    case World.find_exit(ch.current_room_id, dir) do
      nil -> {:error, :no_exit}
      exit -> ch |> change(%{current_room_id: exit.to_room_id}) |> Repo.update()
    end
  end

  defp first_room_id do
    Repo.one!(from r in Room, select: r.id, limit: 1)
  end
end

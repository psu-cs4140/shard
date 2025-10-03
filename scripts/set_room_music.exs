alias Shard.{Repo}
alias Shard.Map.Room

fields = Room.__schema__(:fields)

room =
  cond do
    :slug in fields ->
      import Ecto.Query, only: [from: 2]
      Repo.one(from r in Room, where: r.slug == ^"lobby", limit: 1) ||
        Repo.one(from r in Room, limit: 1)

    :name in fields ->
      import Ecto.Query, only: [from: 2]
      Repo.one(from r in Room, where: r.name == ^"lobby", limit: 1) ||
        Repo.one(from r in Room, limit: 1)

    true ->
      import Ecto.Query, only: [from: 2]
      Repo.one(from r in Room, limit: 1)
  end

if room do
  room
  |> Ecto.Changeset.change(%{
    music_key: "freepd/organ_filler.mp3", # relative under /audio
    music_volume: 20,                     # percent (0..100)
    music_loop: true
  })
  |> Repo.update!()

  IO.puts("Updated room #{room.id} (#{room.name || "unnamed"}) → freepd/organ_filler.mp3")
else
  IO.puts("No rooms found. Create one in Admin → Rooms.")
end

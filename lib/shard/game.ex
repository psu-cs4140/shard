defmodule Shard.Game do
  import Ecto.Query, only: [from: 2]
  alias Shard.Repo
  alias Shard.World.{Room, Exit}

  @exit_fields Exit.__schema__(:fields)

  @from_field (cond do
                 :from_id in @exit_fields ->
                   :from_id

                 :from_room_id in @exit_fields ->
                   :from_room_id

                 :source_id in @exit_fields ->
                   :source_id

                 :src_id in @exit_fields ->
                   :src_id

                 :from in @exit_fields ->
                   :from

                 true ->
                   raise "Exit schema missing origin foreign key (from_*). Fields: #{inspect(@exit_fields)}"
               end)

  @to_field (cond do
               :to_id in @exit_fields ->
                 :to_id

               :to_room_id in @exit_fields ->
                 :to_room_id

               :dest_id in @exit_fields ->
                 :dest_id

               :destination_id in @exit_fields ->
                 :destination_id

               :to in @exit_fields ->
                 :to

               true ->
                 raise "Exit schema missing destination foreign key (to_*). Fields: #{inspect(@exit_fields)}"
             end)

  @dir_field (cond do
                :dir in @exit_fields ->
                  :dir

                :direction in @exit_fields ->
                  :direction

                true ->
                  raise "Exit schema missing direction field (:dir or :direction). Fields: #{inspect(@exit_fields)}"
              end)

  @spec move(Room.id(), String.t()) :: {:ok, Room.t()} | {:error, :no_exit}
  def move(room_id, dir) do
    ex =
      Repo.one(
        from e in Exit,
          where: field(e, ^@from_field) == ^room_id and field(e, ^@dir_field) == ^dir,
          limit: 1
      )

    case ex do
      %Exit{} = e ->
        to_id = Map.get(e, @to_field)

        case Repo.get(Room, to_id) do
          %Room{} = room -> {:ok, room}
          _ -> {:error, :no_exit}
        end

      _ ->
        {:error, :no_exit}
    end
  end
end

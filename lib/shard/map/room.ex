defmodule Shard.Map.Room do
  use Ecto.Schema
  import Ecto.Changeset

  @typedoc "Room struct"
  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t() | nil,
          slug: String.t() | nil,
          description: String.t() | nil,
          x_coordinate: integer() | nil,
          y_coordinate: integer() | nil,
          z_coordinate: integer(),
          is_public: boolean(),
          room_type: String.t(),
          properties: map(),
          music_key: String.t() | nil,
          music_volume: integer(),
          music_loop: boolean(),
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @room_types ~w(standard safe_zone shop dungeon treasure_room trap_room)

  schema "rooms" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :x_coordinate, :integer
    field :y_coordinate, :integer
    field :z_coordinate, :integer, default: 0
    field :is_public, :boolean, default: true
    field :room_type, :string, default: "standard"
    field :properties, :map, default: %{}

    # Per-room music config
    field :music_key, :string
    field :music_volume, :integer, default: 70
    field :music_loop, :boolean, default: true

    has_many :doors_from, Shard.Map.Door, foreign_key: :from_room_id
    has_many :doors_to, Shard.Map.Door, foreign_key: :to_room_id

    timestamps()
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [
      :name,
      :slug,
      :description,
      :x_coordinate,
      :y_coordinate,
      :z_coordinate,
      :is_public,
      :room_type,
      :properties,
      :music_key,
      :music_volume,
      :music_loop
    ])
    |> ensure_coords()
    |> ensure_slug()
    |> validate_required([:name, :slug])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:description, max: 1000)
    |> validate_inclusion(:room_type, @room_types)
    |> validate_number(:music_volume, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> validate_music_key()
    |> unique_constraint(:name)
    |> unique_constraint(:slug)
    |> unique_constraint([:x_coordinate, :y_coordinate], name: "rooms_x_y_index")
  end

  # ── Helpers ─────────────────────────────────────────────────────────────

  # Assign random coordinates if none were provided (helps tests avoid collisions)
  defp ensure_coords(changeset) do
    changeset =
      case get_field(changeset, :x_coordinate) do
        nil -> put_change(changeset, :x_coordinate, System.unique_integer([:positive]))
        _ -> changeset
      end

    case get_field(changeset, :y_coordinate) do
      nil -> put_change(changeset, :y_coordinate, System.unique_integer([:positive]))
      _ -> changeset
    end
  end

  # Ensure a slug is present; derive from name if not provided, normalize if provided.
  defp ensure_slug(changeset) do
    current_slug = get_field(changeset, :slug)
    name = get_field(changeset, :name)

    cond do
      is_binary(current_slug) and String.trim(current_slug) != "" ->
        put_change(changeset, :slug, normalize_slug(current_slug))

      is_binary(name) and String.trim(name) != "" ->
        put_change(changeset, :slug, slugify(name))

      true ->
        changeset
    end
  end

  defp slugify(nil), do: nil

  defp slugify(name) when is_binary(name) do
    name
    |> String.downcase()
    |> String.normalize(:nfd)
    |> String.replace(~r/[^a-z0-9\s-]/u, "")
    |> String.replace(~r/\s+/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
  end

  defp normalize_slug(slug) when is_binary(slug) do
    slug
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9-]/u, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
  end

  # Accept nil/empty, otherwise require a file under /priv/static/audio/** if available.
  defp validate_music_key(changeset) do
    validate_change(changeset, :music_key, fn :music_key, key ->
      key = to_string(key || "")

      cond do
        key == "" ->
          []

        function_exported?(Shard.Music, :exists?, 1) and Shard.Music.exists?(key) ->
          []

        true ->
          [music_key: "file not found under /audio"]
      end
    end)
  end
end

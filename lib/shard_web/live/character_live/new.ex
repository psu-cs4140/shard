defmodule ShardWeb.CharacterLive.New do
  use ShardWeb, :live_view

  alias Shard.Characters
  alias Shard.Characters.Character

  import ShardWeb.CoreComponents

  @random_names [
    "Aldric",
    "Lyra",
    "Corvin",
    "Seraphine",
    "Darius",
    "Elowen",
    "Kael",
    "Morrigan",
    "Thorne",
    "Nyx",
    "Rowan",
    "Isolde",
    "Garrick",
    "Lirael",
    "Bram",
    "Eira",
    "Silas",
    "Valen",
    "Riven",
    "Cassia",
    "Orin",
    "Maelis",
    "Draven",
    "Selene",
    "Kade",
    "Fiora",
    "Lucan",
    "Tamsin",
    "Varyn",
    "Ophel"
  ]

  @class_options [
    {"Warrior", "warrior"},
    {"Mage", "mage"},
    {"Rogue", "rogue"},
    {"Cleric", "cleric"},
    {"Ranger", "ranger"}
  ]

  @race_options [
    {"Human", "human"},
    {"Elf", "elf"},
    {"Dwarf", "dwarf"},
    {"Halfling", "halfling"},
    {"Orc", "orc"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    changeset = Characters.change_character(%Character{})

    {:ok,
     socket
     |> assign(:page_title, "Create Character")
     |> assign(:character, %Character{})
     |> assign(:class_options, @class_options)
     |> assign(:race_options, @race_options)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"character" => character_params}, socket) do
    changeset =
      socket.assigns.character
      |> Characters.change_character(character_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"character" => character_params}, socket) do
    save_character(socket, character_params)
  end

  def handle_event("randomize_name", _params, socket) do
    {:noreply, assign_randomized_field(socket, "name", Enum.random(@random_names))}
  end

  def handle_event("randomize_race", _params, socket) do
    {_label, value} = Enum.random(@race_options)

    {:noreply, assign_randomized_field(socket, "race", value)}
  end

  def handle_event("randomize_class", _params, socket) do
    {_label, value} = Enum.random(@class_options)

    {:noreply, assign_randomized_field(socket, "class", value)}
  end

  defp save_character(socket, character_params) do
    # Add the current user's ID to the character params
    character_params = Map.put(character_params, "user_id", socket.assigns.current_scope.user.id)

    case Characters.create_character(character_params) do
      {:ok, _character} ->
        {:noreply,
         socket
         |> put_flash(:info, "Character created successfully")
         |> push_navigate(to: ~p"/characters")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp assign_randomized_field(socket, field, value) do
    params =
      socket.assigns.form.source.params
      |> case do
        nil -> %{}
        params -> params
      end
      |> Map.put(field, value)

    changeset =
      socket.assigns.character
      |> Characters.change_character(params)
      |> maybe_restore_action(socket.assigns.form.source.action)

    assign(socket, form: to_form(changeset))
  end

  defp maybe_restore_action(changeset, nil), do: changeset
  defp maybe_restore_action(changeset, action), do: Map.put(changeset, :action, action)
end

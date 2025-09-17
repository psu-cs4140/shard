defmodule ShardWeb.CharacterLive.New do
  use ShardWeb, :live_view

  alias Shard.Characters
  alias Shard.Characters.Character

  @impl true
  def mount(_params, _session, socket) do
    changeset = Characters.change_character(%Character{})

    {:ok,
     socket
     |> assign(:page_title, "Create Character")
     |> assign(:character, %Character{})
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

  defp save_character(socket, character_params) do
    # Add the current user's ID to the character params
    character_params = Map.put(character_params, "user_id", socket.assigns.current_user.id)

    case Characters.create_character(character_params) do
      {:ok, character} ->
        {:noreply,
         socket
         |> put_flash(:info, "Character created successfully")
         |> push_navigate(to: ~p"/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end

defmodule ShardWeb.AdminLive.Characters do
  use ShardWeb, :live_view
  import Ecto.Query

  alias Shard.Characters
  alias Shard.Characters.Character
  alias Shard.Repo

  @impl true
  def mount(_params, _session, socket) do
    characters = list_all_characters()

    {:ok,
     socket
     |> assign(:characters, characters)
     |> assign(:page_title, "Admin - All Characters")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    character = Characters.get_character!(id)
    {:ok, _} = Characters.delete_character(character)

    characters = list_all_characters()

    {:noreply,
     socket
     |> put_flash(:info, "Character deleted successfully")
     |> assign(:characters, characters)}
  end

  @impl true
  def handle_event("validate", %{"character" => character_params}, socket) do
    changeset =
      socket.assigns.character
      |> Characters.change_character(character_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"character" => character_params}, socket) do
    save_character(socket, socket.assigns.live_action, character_params)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    character = Characters.get_character!(id)
    changeset = Characters.change_character(character)

    socket
    |> assign(:page_title, "Edit Character")
    |> assign(:character, character)
    |> assign(:form, to_form(changeset))
  end

  defp apply_action(socket, :new, _params) do
    character = %Character{}
    changeset = Characters.change_character(character)

    socket
    |> assign(:page_title, "New Character")
    |> assign(:character, character)
    |> assign(:form, to_form(changeset))
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    character = Characters.get_character!(id)

    socket
    |> assign(:page_title, "Character Details")
    |> assign(:character, character)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Admin - All Characters")
    |> assign(:character, nil)
  end

  defp save_character(socket, :edit, character_params) do
    case Characters.update_character(socket.assigns.character, character_params) do
      {:ok, _character} ->
        characters = list_all_characters()

        {:noreply,
         socket
         |> put_flash(:info, "Character updated successfully")
         |> assign(:characters, characters)
         |> push_patch(to: ~p"/admin/characters")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_character(socket, :new, character_params) do
    case Characters.create_character(character_params) do
      {:ok, _character} ->
        characters = list_all_characters()

        {:noreply,
         socket
         |> put_flash(:info, "Character created successfully")
         |> assign(:characters, characters)
         |> push_patch(to: ~p"/admin/characters")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp list_all_characters do
    from(c in Character,
      join: u in assoc(c, :user),
      select: %{c | user: u},
      order_by: [asc: c.inserted_at, asc: c.id]
    )
    |> Repo.all()
  end
end

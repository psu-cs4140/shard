defmodule ShardWeb.WorkshopLive do
  use ShardWeb, :live_view

  alias Shard.{Characters, Workshop}

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user
    characters = Characters.get_characters_by_user(current_user.id)
    selected_character = List.first(characters)

    {:ok,
     socket
     |> assign(:page_title, "Workshop")
     |> assign(:characters, characters)
     |> assign(:selected_character, selected_character)
     |> assign_recipes()}
  end

  @impl true
  def handle_event("select_character", %{"character_id" => character_id}, socket) do
    selected =
      case Integer.parse(character_id) do
        {id, ""} ->
          Enum.find(socket.assigns.characters, &(&1.id == id))

        _ ->
          nil
      end

    socket =
      socket
      |> assign(:selected_character, selected)
      |> assign_recipes()

    {:noreply, socket}
  end

  def handle_event("craft_dagger", _params, socket),
    do: craft(socket, :craft_dagger)

  def handle_event("craft_stone_axe", _params, socket),
    do: craft(socket, :craft_stone_axe)

  def handle_event("craft_club", _params, socket),
    do: craft(socket, :craft_club)

  def handle_event("craft_torch", _params, socket),
    do: craft(socket, :craft_torch)

  def handle_event("craft_foragers_pack", _params, socket),
    do: craft(socket, :craft_foragers_pack)

  defp craft(socket, recipe_key) do
    case socket.assigns.selected_character do
      nil ->
        {:noreply, put_flash(socket, :error, "Select a character to craft items.")}

      character ->
        case Workshop.craft(character.id, recipe_key) do
          {:ok, recipe} ->
            updated_character = Characters.get_character!(character.id)

            socket =
              socket
              |> put_flash(:info, "You craft a #{recipe.name}.")
              |> assign(:selected_character, updated_character)
              |> assign(:characters, refresh_characters(socket.assigns.characters, updated_character))
              |> assign_recipes()

            {:noreply, socket}

          {:error, :insufficient_materials} ->
            {:noreply, put_flash(socket, :error, "You do not have the required materials.")}

          {:error, {:item_not_found, item_name}} ->
            {:noreply,
             put_flash(socket, :error, "Missing item definition: #{item_name}. Please contact an admin.")}

          {:error, reason} ->
            {:noreply,
             put_flash(socket, :error, "Crafting failed: #{inspect(reason)}")}
        end
    end
  end

  defp refresh_characters(characters, updated_character) do
    Enum.map(characters, fn character ->
      if character.id == updated_character.id do
        updated_character
      else
        character
      end
    end)
  end

  defp assign_recipes(socket) do
    character_id = socket.assigns.selected_character && socket.assigns.selected_character.id
    assign(socket, :recipes, Workshop.recipes_for_character(character_id))
  end
end

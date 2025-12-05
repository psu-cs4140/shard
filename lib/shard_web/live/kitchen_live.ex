defmodule ShardWeb.KitchenLive do
  use ShardWeb, :live_view

  alias Shard.{Characters, Kitchen}

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user
    characters = Characters.get_characters_by_user(current_user.id)
    selected_character = List.first(characters)

    {:ok,
     socket
     |> assign(:page_title, "Kitchen")
     |> assign(:characters, characters)
     |> assign(:selected_character, selected_character)
     |> assign_recipes()}
  end

  @impl true
  def handle_event("select_character", %{"character_id" => character_id}, socket) do
    selected =
      case Integer.parse(character_id) do
        {id, ""} -> Enum.find(socket.assigns.characters, &(&1.id == id))
        _ -> nil
      end

    socket =
      socket
      |> assign(:selected_character, selected)
      |> assign_recipes()

    {:noreply, socket}
  end

  def handle_event("cook_roasted_seeds", _params, socket),
    do: cook(socket, :cook_roasted_seeds)

  def handle_event("cook_cooked_mushroom", _params, socket),
    do: cook(socket, :cook_cooked_mushroom)

  def handle_event("cook_mushroom_skewer", _params, socket),
    do: cook(socket, :cook_mushroom_skewer)

  def handle_event("cook_sweet_glazed_seeds", _params, socket),
    do: cook(socket, :cook_sweet_glazed_seeds)

  def handle_event("cook_forest_stew", _params, socket),
    do: cook(socket, :cook_forest_stew)

  defp cook(socket, recipe_key) do
    case socket.assigns.selected_character do
      nil ->
        {:noreply, put_flash(socket, :error, "Select a character to cook food.")}

      character ->
        case Kitchen.cook(character.id, recipe_key) do
          {:ok, recipe} ->
            updated_character = Characters.get_character!(character.id)

            socket =
              socket
              |> put_flash(:info, "You cook #{recipe.name}.")
              |> assign(:selected_character, updated_character)
              |> assign(
                :characters,
                refresh_characters(socket.assigns.characters, updated_character)
              )
              |> assign_recipes()

            {:noreply, socket}

          {:error, :insufficient_materials} ->
            {:noreply, put_flash(socket, :error, "You do not have the required ingredients.")}

          {:error, {:item_not_found, item_name}} ->
            {:noreply,
             put_flash(
               socket,
               :error,
               "Missing item definition: #{item_name}. Please contact an admin."
             )}

          {:error, reason} ->
            {:noreply, put_flash(socket, :error, "Cooking failed: #{inspect(reason)}")}
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
    assign(socket, :recipes, Kitchen.recipes_for_character(character_id))
  end
end

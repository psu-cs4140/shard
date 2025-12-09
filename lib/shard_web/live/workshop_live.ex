defmodule ShardWeb.WorkshopLive do
  use ShardWeb, :live_view

  alias Shard.{Characters, Cooking, Workshop}

  @tabs ~w(crafting cooking furnace)

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user
    characters = Characters.get_characters_by_user(current_user.id)
    selected_character = List.first(characters)

    {:ok,
     socket
     |> assign(:page_title, "Foundry & Kitchen")
     |> assign(:characters, characters)
     |> assign(:selected_character, selected_character)
     |> assign(:active_tab, "crafting")
     |> assign_recipes()
     |> assign_cooking_recipes()
     |> assign_furnace_recipes()}
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
      |> assign_cooking_recipes()
      |> assign_furnace_recipes()

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

  def handle_event("craft_copper_dagger", _params, socket),
    do: craft(socket, :craft_copper_dagger)

  def handle_event("craft_copper_pickaxe", _params, socket),
    do: craft(socket, :craft_copper_pickaxe)

  def handle_event("craft_iron_sword", _params, socket),
    do: craft(socket, :craft_iron_sword)

  def handle_event("craft_iron_shield", _params, socket),
    do: craft(socket, :craft_iron_shield)

  def handle_event("craft_gemmed_amulet", _params, socket),
    do: craft(socket, :craft_gemmed_amulet)

  def handle_event("smelt_copper_bar", _params, socket),
    do: smelt(socket, :smelt_copper_bar)

  def handle_event("smelt_iron_bar", _params, socket),
    do: smelt(socket, :smelt_iron_bar)

  def handle_event("cook_recipe", %{"key" => key}, socket),
    do: cook(socket, key)

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    tab =
      if tab in @tabs do
        tab
      else
        socket.assigns.active_tab
      end

    {:noreply, assign(socket, :active_tab, tab)}
  end

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
              |> assign(
                :characters,
                refresh_characters(socket.assigns.characters, updated_character)
              )
              |> assign_recipes()
              |> assign_cooking_recipes()
              |> assign_furnace_recipes()

            {:noreply, socket}

          {:error, :insufficient_materials} ->
            {:noreply, put_flash(socket, :error, "You do not have the required materials.")}

          {:error, {:item_not_found, item_name}} ->
            {:noreply,
             put_flash(
               socket,
               :error,
               "Missing item definition: #{item_name}. Please contact an admin."
             )}

          {:error, reason} ->
            {:noreply, put_flash(socket, :error, "Crafting failed: #{inspect(reason)}")}
        end
    end
  end

  defp smelt(socket, recipe_key) do
    case socket.assigns.selected_character do
      nil ->
        {:noreply, put_flash(socket, :error, "Select a character to smelt items.")}

      character ->
        case Workshop.smelt(character.id, recipe_key) do
          {:ok, recipe} ->
            updated_character = Characters.get_character!(character.id)

            socket =
              socket
              |> put_flash(:info, "You smelt a #{recipe.name}.")
              |> assign(:selected_character, updated_character)
              |> assign(
                :characters,
                refresh_characters(socket.assigns.characters, updated_character)
              )
              |> assign_recipes()
              |> assign_cooking_recipes()
              |> assign_furnace_recipes()

            {:noreply, socket}

          {:error, :insufficient_materials} ->
            {:noreply, put_flash(socket, :error, "You do not have the required ore or fuel.")}

          {:error, :insufficient_fuel} ->
            {:noreply, put_flash(socket, :error, "You do not have enough fuel.")}

          {:error, {:item_not_found, item_name}} ->
            {:noreply,
             put_flash(
               socket,
               :error,
               "Missing item definition: #{item_name}. Please contact an admin."
             )}

          {:error, reason} ->
            {:noreply, put_flash(socket, :error, "Smelting failed: #{inspect(reason)}")}
        end
    end
  end

  defp cook(socket, recipe_key) do
    case socket.assigns.selected_character do
      nil ->
        {:noreply, put_flash(socket, :error, "Select a character to cook food.")}

      character ->
        atom_key =
          case recipe_key do
            k when is_atom(k) -> k
            k when is_binary(k) -> safe_to_existing_atom(k)
            _ -> nil
          end

        with {:key, true} <- {:key, not is_nil(atom_key)},
             {:ok, recipe} <- Cooking.cook(character.id, atom_key) do
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
            |> assign_cooking_recipes()
            |> assign_furnace_recipes()

          {:noreply, socket}
        else
          {:key, _} ->
            {:noreply, put_flash(socket, :error, "Unknown cooking recipe.")}

          {:error, :insufficient_materials} ->
            {:noreply,
             put_flash(socket, :error, "You do not have the required ingredients to cook this.")}

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
    assign(socket, :recipes, Workshop.recipes_for_character(character_id))
  end

  defp assign_cooking_recipes(socket) do
    character_id = socket.assigns.selected_character && socket.assigns.selected_character.id
    assign(socket, :cooking_recipes, Cooking.recipes_for_character(character_id))
  end

  defp assign_furnace_recipes(socket) do
    character_id = socket.assigns.selected_character && socket.assigns.selected_character.id
    assign(socket, :furnace_recipes, Workshop.furnace_recipes_for_character(character_id))
  end

  defp safe_to_existing_atom(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> nil
    end
  end
end

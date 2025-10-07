defmodule ShardWeb.CharacterSelectionComponent do
  @moduledoc """
  LiveComponent for character selection and creation.
  Used within MapSelectionLive to handle character-related interactions.
  """
  use ShardWeb, :live_component
  alias Shard.Characters
  alias Shard.Characters.Character

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       modal_mode: :select,
       character_form: to_form(Characters.change_character(%Character{}))
     )}
  end

  @impl true
  def update(assigns, socket) do
    # Determine initial mode based on whether characters exist
    modal_mode =
      if Enum.empty?(assigns.characters) do
        :create
      else
        socket.assigns[:modal_mode] || :select
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(modal_mode: modal_mode)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @show do %>
        <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div class="bg-white rounded-lg p-6 max-w-md w-full mx-4">
            <h3 class="text-xl font-bold text-gray-900 mb-4">
              {if @modal_mode == :create, do: "Create New Character", else: "Choose Your Character"}
            </h3>

            <%= if @modal_mode == :create do %>
              <!-- Character Creation Form -->
              <.simple_form
                for={@character_form}
                id="character-form"
                phx-change="validate_character"
                phx-submit="create_character"
                phx-target={@myself}
                class="space-y-4"
              >
                <.input field={@character_form[:name]} type="text" label="Character Name" required />
                <.input
                  field={@character_form[:class]}
                  type="select"
                  label="Class"
                  prompt="Choose a class"
                  options={[
                    {"Warrior", "warrior"},
                    {"Mage", "mage"},
                    {"Rogue", "rogue"},
                    {"Cleric", "cleric"},
                    {"Ranger", "ranger"}
                  ]}
                  required
                />
                <.input
                  field={@character_form[:race]}
                  type="select"
                  label="Race"
                  prompt="Choose a race"
                  options={[
                    {"Human", "human"},
                    {"Elf", "elf"},
                    {"Dwarf", "dwarf"},
                    {"Halfling", "halfling"},
                    {"Orc", "orc"}
                  ]}
                  required
                />
                <.input field={@character_form[:description]} type="textarea" label="Description" />

                <:actions>
                  <div class="flex space-x-4">
                    <.button phx-disable-with="Creating..." class="flex-1">
                      Create & Enter Map
                    </.button>
                    <.button
                      phx-click="switch_to_select_mode"
                      phx-target={@myself}
                      variant="outline"
                      class="flex-1"
                      type="button"
                    >
                      Back to Selection
                    </.button>
                  </div>
                </:actions>
              </.simple_form>
            <% else %>
              <!-- Character Selection Mode -->
              <%= if Enum.empty?(@characters) do %>
                <p class="text-gray-600 mb-4">
                  You don't have any characters yet. Create your first character to start playing!
                </p>
                <div class="flex flex-col space-y-3">
                  <.button phx-click="switch_to_create_mode" phx-target={@myself} class="w-full">
                    Create Your First Character
                  </.button>
                  <.button
                    phx-click="cancel_map_selection"
                    phx-target={@myself}
                    variant="outline"
                    class="w-full"
                  >
                    Cancel
                  </.button>
                </div>
              <% else %>
                <p class="text-gray-600 mb-2">
                  Found {length(@characters)} character(s). Select one to enter the map:
                </p>
                <div class="space-y-2 mb-4">
                  <%= for character <- @characters do %>
                    <button
                      phx-click="select_character"
                      phx-value-character_id={character.id}
                      phx-target={@myself}
                      class="w-full text-left p-3 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
                    >
                      <div class="font-semibold">{character.name}</div>
                      <div class="text-sm text-gray-600">
                        Level {character.level || 1} {String.capitalize(
                          character.class || "adventurer"
                        )}
                      </div>
                    </button>
                  <% end %>
                </div>

                <div class="flex space-x-3">
                  <.button
                    phx-click="switch_to_create_mode"
                    phx-target={@myself}
                    variant="outline"
                    class="flex-1"
                  >
                    Create New Character
                  </.button>
                  <.button
                    phx-click="cancel_map_selection"
                    phx-target={@myself}
                    variant="outline"
                    class="flex-1"
                  >
                    Cancel
                  </.button>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("select_character", %{"character_id" => character_id}, socket) do
    character =
      Enum.find(socket.assigns.characters, fn char ->
        to_string(char.id) == character_id
      end)

    character_name = if character, do: character.name, else: "Unknown"

    send(self(), {:character_selected, character_id, character_name})
    {:noreply, socket}
  end

  def handle_event("cancel_map_selection", _params, socket) do
    send(self(), :cancel_selection)
    {:noreply, socket}
  end

  def handle_event("switch_to_create_mode", _params, socket) do
    {:noreply, assign(socket, modal_mode: :create)}
  end

  def handle_event("switch_to_select_mode", _params, socket) do
    {:noreply, assign(socket, modal_mode: :select)}
  end

  def handle_event("validate_character", %{"character" => character_params}, socket) do
    changeset =
      %Character{}
      |> Characters.change_character(character_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, character_form: to_form(changeset))}
  end

  def handle_event("create_character", %{"character" => character_params}, socket) do
    # Get user from parent LiveView
    user = get_user_from_parent(socket)

    character_params = Map.put(character_params, "user_id", user.id)

    case Characters.create_character(character_params) do
      {:ok, character} ->
        # Reload characters and notify parent
        characters = Characters.get_characters_by_user(user.id)
        send(self(), {:characters_updated, characters})
        send(self(), {:character_selected, character.id, character.name})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, character_form: to_form(changeset))}
    end
  end

  # Helper to get user from parent socket
  defp get_user_from_parent(socket) do
    # Access parent assigns through the socket
    parent_assigns = socket.assigns

    cond do
      parent_assigns[:current_scope] && parent_assigns.current_scope.user ->
        parent_assigns.current_scope.user

      parent_assigns[:current_user] ->
        parent_assigns.current_user

      true ->
        raise "No authenticated user found"
    end
  end
end

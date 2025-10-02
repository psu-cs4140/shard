defmodule ShardWeb.CharacterLive.FormComponent do
  use ShardWeb, :live_component

  alias Shard.Characters

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Create a new character to begin your adventure</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="character-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Character Name" required />
        <.input
          field={@form[:class]}
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
          field={@form[:race]}
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
        <.input field={@form[:description]} type="textarea" label="Description" />
        <:actions>
          <.button phx-disable-with="Creating...">Create Character</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{character: character} = assigns, socket) do
    changeset = Characters.change_character(character)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"character" => character_params}, socket) do
    changeset =
      socket.assigns.character
      |> Characters.change_character(character_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"character" => character_params}, socket) do
    save_character(socket, socket.assigns.action, character_params)
  end

  defp save_character(socket, :new, character_params) do
    # Add user_id to the character params
    character_params = Map.put(character_params, "user_id", socket.assigns.current_scope.user.id)

    case Characters.create_character(character_params) do
      {:ok, character} ->
        notify_parent({:character_created, character})

        {:noreply,
         socket
         |> put_flash(:info, "Character created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), msg)
end

defmodule ShardWeb.AdminLive.CharacterFormComponent do
  use ShardWeb, :live_component

  alias Shard.Characters
  alias Shard.Users

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div style="padding-left: 3rem;">
        <.header>
          <%= @title %>
          <:subtitle>Use this form to manage character records in your database.</:subtitle>
        </.header>
      </div>

      <.form
        for={@form}
        id="character-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:level]} type="number" label="Level" />
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
        />
        <.input field={@form[:health]} type="number" label="Health" />
        <.input field={@form[:mana]} type="number" label="Mana" />
        <.input field={@form[:strength]} type="number" label="Strength" />
        <.input field={@form[:dexterity]} type="number" label="Dexterity" />
        <.input field={@form[:intelligence]} type="number" label="Intelligence" />
        <.input field={@form[:constitution]} type="number" label="Constitution" />
        <.input field={@form[:experience]} type="number" label="Experience" />
        <.input field={@form[:gold]} type="number" label="Gold" />
        <.input field={@form[:location]} type="text" label="Location" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input
          field={@form[:user_id]}
          type="select"
          label="User"
          prompt="Choose a user"
          options={@user_options}
        />
        <.input field={@form[:is_active]} type="checkbox" label="Active" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Character</.button>
        </:actions>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{character: character} = assigns, socket) do
    changeset = Characters.change_character(character)
    user_options = get_user_options()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:user_options, user_options)
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

  defp save_character(socket, :edit, character_params) do
    case Characters.update_character(socket.assigns.character, character_params) do
      {:ok, character} ->
        notify_parent({:saved, character})

        {:noreply,
         socket
         |> put_flash(:info, "Character updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_character(socket, :new, character_params) do
    case Characters.create_character(character_params) do
      {:ok, character} ->
        notify_parent({:saved, character})

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

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp get_user_options do
    Users.list_users()
    |> Enum.map(&{&1.email, &1.id})
  end
end

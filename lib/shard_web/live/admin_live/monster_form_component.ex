defmodule ShardWeb.AdminLive.MonsterFormComponent do
  use ShardWeb, :live_component

  alias Shard.Monsters
  alias Shard.Map

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage monster records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="monster-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:race]} type="text" label="Race" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:level]} type="number" label="Level" />
        <.input field={@form[:health]} type="number" label="Health" />
        <.input field={@form[:max_health]} type="number" label="Max Health" />
        <.input field={@form[:attack_damage]} type="number" label="Attack Damage" />
        <.input field={@form[:xp_amount]} type="number" label="XP Amount" />
        
        <.input 
          field={@form[:location_id]} 
          type="select" 
          label="Location" 
          prompt="Choose a room"
          options={Enum.map(@rooms, &{&1.name || "Room #{&1.id}", &1.id})}
        />

        <:actions>
          <.button phx-disable-with="Saving...">Save Monster</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{monster: monster} = assigns, socket) do
    changeset = Monsters.change_monster(monster)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)
     |> assign(:rooms, Map.list_rooms())}
  end

  @impl true
  def handle_event("validate", %{"monster" => monster_params}, socket) do
    changeset =
      socket.assigns.monster
      |> Monsters.change_monster(monster_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"monster" => monster_params}, socket) do
    save_monster(socket, socket.assigns.action, monster_params)
  end

  defp save_monster(socket, :edit, monster_params) do
    case Monsters.update_monster(socket.assigns.monster, monster_params) do
      {:ok, monster} ->
        notify_parent({:saved, monster})

        {:noreply,
         socket
         |> put_flash(:info, "Monster updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_monster(socket, :new, monster_params) do
    case Monsters.create_monster(monster_params) do
      {:ok, monster} ->
        notify_parent({:saved, monster})

        {:noreply,
         socket
         |> put_flash(:info, "Monster created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

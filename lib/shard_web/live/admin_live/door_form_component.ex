defmodule ShardWeb.AdminLive.DoorFormComponent do
  use ShardWeb, :live_component

  alias Shard.Map

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage door properties in your application.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="door-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="textarea" label="Description" />

        <.input
          field={@form[:from_realm]}
          type="select"
          label="From Realm"
          options={@realm_options}
          prompt="Select a realm"
        />

        <.input
          field={@form[:from_room_id]}
          type="select"
          label="From Room"
          options={@room_options}
          prompt="Select a room"
        />

        <.input
          field={@form[:to_room_id]}
          type="select"
          label="To Room"
          options={@room_options}
          prompt="Select a room"
        />

        <.input
          field={@form[:to_realm]}
          type="select"
          label="To Realm"
          options={@realm_options}
          prompt="Select a realm"
        />

        <.input
          field={@form[:direction]}
          type="select"
          label="Direction"
          options={[
            {"North", "north"},
            {"South", "south"},
            {"East", "east"},
            {"West", "west"},
            {"Northeast", "northeast"},
            {"Northwest", "northwest"},
            {"Southeast", "southeast"},
            {"Southwest", "southwest"},
            {"Up", "up"},
            {"Down", "down"}
          ]}
          prompt="Select direction"
        />

        <.input
          field={@form[:door_type]}
          type="select"
          label="Door Type"
          options={[
            {"Standard", "standard"},
            {"One Way", "one_way"},
            {"Portal", "portal"},
            {"Hidden", "hidden"}
          ]}
        />

        <.input field={@form[:is_locked]} type="checkbox" label="Is Locked" />
        <.input field={@form[:key_required]} type="text" label="Key Required" />

        <:actions>
          <.button phx-disable-with="Saving...">Save Door</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{door: door} = assigns, socket) do
    changeset = Map.change_door(door)
    rooms = Map.list_rooms()
    room_options = Enum.map(rooms, &{&1.name || "Room #{&1.id}", &1.id})
    
    realms = Map.list_realms()
    realm_options = Enum.map(realms, &{&1, &1})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:room_options, room_options)
     |> assign(:realm_options, realm_options)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"door" => door_params}, socket) do
    changeset =
      socket.assigns.door
      |> Map.change_door(door_params)
      |> Elixir.Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"door" => door_params}, socket) do
    save_door(socket, socket.assigns.action, door_params)
  end

  defp save_door(socket, :edit, door_params) do
    case Map.update_door(socket.assigns.door, door_params) do
      {:ok, door} ->
        notify_parent({:saved, door})

        {:noreply,
         socket
         |> put_flash(:info, "Door updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_door(socket, :new, door_params) do
    case Map.create_door(door_params) do
      {:ok, door} ->
        notify_parent({:saved, door})

        {:noreply,
         socket
         |> put_flash(:info, "Door created successfully")
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

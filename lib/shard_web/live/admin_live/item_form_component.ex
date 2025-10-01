defmodule ShardWeb.AdminLive.ItemFormComponent do
  use ShardWeb, :live_component

  alias Shard.Items

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div style="padding-left: 3rem;">
        <.header>
          {@title}
          <:subtitle>Use this form to manage item records in your database.</:subtitle>
        </.header>
      </div>

      <.simple_form
        for={@form}
        id="item-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input
          field={@form[:item_type]}
          type="select"
          label="Item Type"
          prompt="Choose a type"
          options={Enum.map(Shard.Items.Item.item_types(), &{String.capitalize(&1), &1})}
        />
        <.input
          field={@form[:rarity]}
          type="select"
          label="Rarity"
          options={Enum.map(Shard.Items.Item.rarities(), &{String.capitalize(&1), &1})}
        />
        <.input field={@form[:value]} type="number" label="Value (gold)" />
        <.input field={@form[:weight]} type="number" label="Weight (lbs)" step="0.1" />
        <.input field={@form[:stackable]} type="checkbox" label="Stackable" />
        <.input field={@form[:max_stack_size]} type="number" label="Max Stack Size" />
        <.input field={@form[:usable]} type="checkbox" label="Usable" />
        <.input field={@form[:equippable]} type="checkbox" label="Equippable" />
        <.input
          field={@form[:equipment_slot]}
          type="select"
          label="Equipment Slot"
          prompt="Choose a slot"
          options={Enum.map(Shard.Items.Item.equipment_slots(), &{String.capitalize(&1), &1})}
        />
        <.input field={@form[:icon]} type="text" label="Icon" />
        <.input field={@form[:is_active]} type="checkbox" label="Active" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Item</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{item: item} = assigns, socket) do
    changeset = Items.change_item(item)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"item" => item_params}, socket) do
    changeset =
      socket.assigns.item
      |> Items.change_item(item_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"item" => item_params}, socket) do
    save_item(socket, socket.assigns.action, item_params)
  end

  defp save_item(socket, :edit, item_params) do
    case Items.update_item(socket.assigns.item, item_params) do
      {:ok, item} ->
        notify_parent({:saved, item})

        {:noreply,
         socket
         |> put_flash(:info, "Item updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_item(socket, :new, item_params) do
    case Items.create_item(item_params) do
      {:ok, item} ->
        notify_parent({:saved, item})

        {:noreply,
         socket
         |> put_flash(:info, "Item created successfully")
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

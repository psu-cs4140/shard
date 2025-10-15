defmodule ShardWeb.AdminLive.Monsters do
  use ShardWeb, :live_view

  alias Shard.Monsters
  alias Shard.Monsters.Monster
  alias Shard.Map

  import ShardWeb.Layouts, only: [flash_group: 1]


  @impl true
  def mount(_params, _session, socket) do
    monsters = Monsters.list_monsters()
    rooms = Map.list_rooms()

    {:ok,
     assign(socket,
       monsters: monsters,
       rooms: rooms,
       show_form: false,
       form_monster: nil,
       form_title: "Create Monster"
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # NOTE: private helper (no @impl)
  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Monsters Administration")
    |> assign(:show_form, false)
  end

  defp apply_action(socket, :new, _params) do
    changeset = Monsters.change_monster(%Monster{})

    socket
    |> assign(:page_title, "New Monster")
    |> assign(:show_form, true)
    |> assign(:form_monster, %Monster{})
    |> assign(:form_title, "Create Monster")
    |> assign(:changeset, changeset)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    monster = Monsters.get_monster!(id)
    changeset = Monsters.change_monster(monster)

    socket
    |> assign(:page_title, "Edit Monster")
    |> assign(:show_form, true)
    |> assign(:form_monster, monster)
    |> assign(:form_title, "Edit Monster")
    |> assign(:changeset, changeset)
  end

  @impl true
  def handle_event("edit_monster", %{"id" => id}, socket) do
    monster = Monsters.get_monster!(id)
    changeset = Monsters.change_monster(monster)

    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:form_monster, monster)
     |> assign(:form_title, "Edit Monster")
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("delete_monster", %{"id" => id}, socket) do
    monster = Monsters.get_monster!(id)
    {:ok, _} = Monsters.delete_monster(monster)

    monsters = Monsters.list_monsters()

    {:noreply,
     socket
     |> assign(:monsters, monsters)
     |> put_flash(:info, "Monster deleted successfully")}
  end

  @impl true
  def handle_event("cancel_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_form, false)
     |> push_patch(to: ~p"/admin/monsters")}
  end

  @impl true
  def handle_event("validate", %{"monster" => monster_params}, socket) do
    changeset =
      socket.assigns.form_monster
      |> Monsters.change_monster(monster_params)
      |> Elixir.Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save_monster", %{"monster" => monster_params}, socket) do
    # Clean up empty string values that should be nil
    cleaned_params =
      monster_params
      |> Enum.map(fn {k, v} -> if v == "", do: {k, nil}, else: {k, v} end)
      |> Enum.into(%{})

    case socket.assigns.form_monster.id do
      nil -> create_monster(socket, cleaned_params)
      _id -> update_monster(socket, cleaned_params)
    end
  end

  defp create_monster(socket, monster_params) do
    case Monsters.create_monster(monster_params) do
      {:ok, _monster} ->
        monsters = Monsters.list_monsters()

        {:noreply,
         socket
         |> assign(:monsters, monsters)
         |> assign(:show_form, false)
         |> put_flash(:info, "Monster created successfully")
         |> push_patch(to: ~p"/admin/monsters")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp update_monster(socket, monster_params) do
    case Monsters.update_monster(socket.assigns.form_monster, monster_params) do
      {:ok, _monster} ->
        monsters = Monsters.list_monsters()

        {:noreply,
         socket
         |> assign(:monsters, monsters)
         |> assign(:show_form, false)
         |> put_flash(:info, "Monster updated successfully")
         |> push_patch(to: ~p"/admin/monsters")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6">
      <.flash_group flash={@flash} />
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-3xl font-bold">Monsters Administration</h1>
        <.link
          patch={~p"/admin/monsters/new"}
          class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg inline-block"
        >
          + New Monster
        </.link>
      </div>

      <%= if @show_form do %>
        <div class="bg-white rounded-lg shadow-lg p-6 mb-6">
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-xl font-semibold">{@form_title}</h2>
            <button phx-click="cancel_form" class="text-gray-500 hover:text-gray-700">✕</button>
          </div>

          <%= if assigns[:changeset] do %>
            <.simple_form for={to_form(@changeset)} phx-submit="save_monster" phx-change="validate" id="monster-form">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <% form = to_form(@changeset) %>
                <.input field={form[:name]} label="Name" required />
                <.input field={form[:race]} label="Race" required />

                <.input field={form[:level]} type="number" label="Level" />
                <.input field={form[:health]} type="number" label="Health" />

                <.input field={form[:max_health]} type="number" label="Max Health" />
                <.input field={form[:attack_damage]} type="number" label="Attack Damage" />

                <.input field={form[:xp_amount]} type="number" label="XP Amount" />
                <.input
                  field={form[:location_id]}
                  type="select"
                  label="Location"
                  options={[{"None", nil} | Enum.map(@rooms, &{&1.name || "Room #{&1.id}", &1.id})]}
                />
              </div>

              <.input field={form[:description]} type="textarea" label="Description" />

              <div class="flex justify-end space-x-2">
                <.link
                  patch={~p"/admin/monsters"}
                  class="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 inline-block"
                >
                  Cancel
                </.link>
                <button
                  type="submit"
                  class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Save Monster
                </button>
              </div>
            </.simple_form>
          <% else %>
            <div class="text-center py-8">
              <p class="text-gray-500">Loading form...</p>
            </div>
          <% end %>
        </div>
      <% end %>

      <div class="bg-white rounded-lg shadow overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Name
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Race
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Level
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Health
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Attack
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                XP Reward
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Location
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <%= for monster <- @monsters do %>
              <tr id={"monster-#{monster.id}"}>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm font-medium text-gray-900">{monster.name}</div>
                  <div class="text-sm text-gray-500">
                    {String.slice(monster.description || "", 0, 50)}{if String.length(
                                                                          monster.description || ""
                                                                        ) > 50,
                                                                        do: "..."}
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800">
                    {String.capitalize(monster.race)}
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {monster.level}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {monster.health}/{monster.max_health}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {monster.attack_damage}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {monster.xp_amount}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  <%= if monster.location_id do %>
                    <% room = Enum.find(@rooms, &(&1.id == monster.location_id)) %>
                    {if room, do: room.name || "Room #{room.id}", else: "Unknown Room"}
                  <% else %>
                    -
                  <% end %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                  <.link
                    patch={~p"/admin/monsters/#{monster.id}/edit"}
                    class="text-indigo-600 hover:text-indigo-900 mr-3"
                  >
                    Edit
                  </.link>
                  <button
                    phx-click="delete_monster"
                    phx-value-id={monster.id}
                    data-confirm="Are you sure you want to delete this monster?"
                    class="text-red-600 hover:text-red-900"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end

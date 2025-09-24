defmodule ShardWeb.AdminLive.Npcs do
  use ShardWeb, :live_view

  alias Shard.Npcs
  alias Shard.Npcs.Npc
  alias Shard.Repo

  @impl true
  def mount(_params, _session, socket) do
    # Ensure tutorial NPCs exist
    ensure_tutorial_npcs_exist()
    
    npcs = Npcs.list_npcs_with_preloads()
    rooms = Npcs.list_rooms()
    
    {:ok, assign(socket, 
      npcs: npcs, 
      rooms: rooms,
      show_form: false,
      form_npc: nil,
      form_title: "Create NPC"
    )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "NPCs Administration")
    |> assign(:show_form, false)
  end

  defp apply_action(socket, :new, _params) do
    changeset = Npcs.change_npc(%Npc{})
    socket
    |> assign(:page_title, "New NPC")
    |> assign(:show_form, true)
    |> assign(:form_npc, %Npc{})
    |> assign(:form_title, "Create NPC")
    |> assign(:changeset, changeset)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    npc = Npcs.get_npc_with_preloads!(id)
    changeset = Npcs.change_npc(npc)
    
    socket
    |> assign(:page_title, "Edit NPC")
    |> assign(:show_form, true)
    |> assign(:form_npc, npc)
    |> assign(:form_title, "Edit NPC")
    |> assign(:changeset, changeset)
  end

  @impl true
  def handle_event("edit_npc", %{"id" => id}, socket) do
    npc = Npcs.get_npc_with_preloads!(id)
    changeset = Npcs.change_npc(npc)
    
    {:noreply,
      socket
      |> assign(:show_form, true)
      |> assign(:form_npc, npc)
      |> assign(:form_title, "Edit NPC")
      |> assign(:changeset, changeset)
    }
  end

  @impl true
  def handle_event("delete_npc", %{"id" => id}, socket) do
    npc = Npcs.get_npc!(id)
    {:ok, _} = Npcs.delete_npc(npc)
    
    npcs = Npcs.list_npcs_with_preloads()
    
    {:noreply, 
      socket
      |> assign(:npcs, npcs)
      |> put_flash(:info, "NPC deleted successfully")
    }
  end

  @impl true
  def handle_event("cancel_form", _params, socket) do
    {:noreply, 
      socket
      |> assign(:show_form, false)
      |> push_patch(to: ~p"/admin/npcs")
    }
  end

  @impl true
  def handle_event("save_npc", %{"npc" => npc_params}, socket) do
    # Clean up empty string values that should be nil
    cleaned_params = 
      npc_params
      |> Enum.map(fn {k, v} -> 
        case v do
          "" -> {k, nil}
          v -> {k, v}
        end
      end)
      |> Enum.into(%{})
    
    case socket.assigns.form_npc.id do
      nil -> create_npc(socket, cleaned_params)
      _id -> update_npc(socket, cleaned_params)
    end
  end

  defp create_npc(socket, npc_params) do
    case Npcs.create_npc(npc_params) do
      {:ok, _npc} ->
        npcs = Npcs.list_npcs_with_preloads()
        
        {:noreply,
          socket
          |> assign(:npcs, npcs)
          |> assign(:show_form, false)
          |> put_flash(:info, "NPC created successfully")
          |> push_patch(to: ~p"/admin/npcs")
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp update_npc(socket, npc_params) do
    case Npcs.update_npc(socket.assigns.form_npc, npc_params) do
      {:ok, _npc} ->
        npcs = Npcs.list_npcs_with_preloads()
        
        {:noreply,
          socket
          |> assign(:npcs, npcs)
          |> assign(:show_form, false)
          |> put_flash(:info, "NPC updated successfully")
          |> push_patch(to: ~p"/admin/npcs")
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-3xl font-bold">NPCs Administration</h1>
        <.link 
          patch={~p"/admin/npcs/new"}
          class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg inline-block"
        >
          + New NPC
        </.link>
      </div>

      <%= if @show_form do %>
        <div class="bg-white rounded-lg shadow-lg p-6 mb-6">
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-xl font-semibold"><%= @form_title %></h2>
            <button 
              phx-click="cancel_form"
              class="text-gray-500 hover:text-gray-700"
            >
              ✕
            </button>
          </div>
          
          <%= if assigns[:changeset] do %>
            <.simple_form 
              for={to_form(@changeset)}
              phx-submit="save_npc"
              id="npc-form"
            >
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <% form = to_form(@changeset) %>
                <.input field={form[:name]} label="Name" required />
                <.input field={form[:npc_type]} type="select" label="Type" 
                  options={[
                    {"Neutral", "neutral"},
                    {"Friendly", "friendly"}, 
                    {"Hostile", "hostile"},
                    {"Merchant", "merchant"},
                    {"Quest Giver", "quest_giver"}
                  ]} />
                
                <.input field={form[:level]} type="number" label="Level" />
                <.input field={form[:faction]} label="Faction" />
                
                <.input field={form[:health]} type="number" label="Health" />
                <.input field={form[:max_health]} type="number" label="Max Health" />
                
                <.input field={form[:mana]} type="number" label="Mana" />
                <.input field={form[:max_mana]} type="number" label="Max Mana" />
                
                <.input field={form[:strength]} type="number" label="Strength" />
                <.input field={form[:dexterity]} type="number" label="Dexterity" />
                
                <.input field={form[:intelligence]} type="number" label="Intelligence" />
                <.input field={form[:constitution]} type="number" label="Constitution" />
                
                <.input field={form[:experience_reward]} type="number" label="Experience Reward" />
                <.input field={form[:gold_reward]} type="number" label="Gold Reward" />
                
                <.input field={form[:location_x]} type="number" label="Location X" />
                <.input field={form[:location_y]} type="number" label="Location Y" />
                
                <.input field={form[:room_id]} type="select" label="Room" 
                  options={[{"None", nil} | Enum.map(@rooms, &{&1.name || "Room #{&1.id}", &1.id})]} />
                
                <.input field={form[:movement_pattern]} type="select" label="Movement Pattern"
                  options={[
                    {"Stationary", "stationary"},
                    {"Patrol", "patrol"},
                    {"Random", "random"},
                    {"Follow", "follow"}
                  ]} />
                
                <.input field={form[:aggression_level]} type="number" label="Aggression Level (0-10)" />
                <.input field={form[:respawn_time]} type="number" label="Respawn Time (seconds)" />
              </div>
              
              <.input field={form[:description]} type="textarea" label="Description" />
              <.input field={form[:dialogue]} type="textarea" label="Dialogue" />
              
              <div class="flex items-center space-x-4">
                <.input field={form[:is_active]} type="checkbox" label="Active" />
              </div>
              
              <div class="flex justify-end space-x-2">
                <.link 
                  patch={~p"/admin/npcs"}
                  class="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 inline-block"
                >
                  Cancel
                </.link>
                <button 
                  type="submit"
                  class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Save NPC
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
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Level</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Location</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Room</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <%= for npc <- @npcs do %>
              <tr>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm font-medium text-gray-900"><%= npc.name %></div>
                  <div class="text-sm text-gray-500"><%= String.slice(npc.description || "", 0, 50) %><%= if String.length(npc.description || "") > 50, do: "..." %></div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{npc_type_color(npc.npc_type)}"}>
                    <%= String.capitalize(npc.npc_type) %>
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  <%= npc.level %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  <%= if npc.location_x && npc.location_y do %>
                    (<%= npc.location_x %>, <%= npc.location_y %>)
                  <% else %>
                    -
                  <% end %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  <%= if npc.room do %>
                    <%= npc.room.name || "Room #{npc.room.id}" %>
                  <% else %>
                    -
                  <% end %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{if npc.is_active, do: "bg-green-100 text-green-800", else: "bg-red-100 text-red-800"}"}>
                    <%= if npc.is_active, do: "Active", else: "Inactive" %>
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                  <.link 
                    patch={~p"/admin/npcs/#{npc.id}/edit"}
                    class="text-indigo-600 hover:text-indigo-900 mr-3"
                  >
                    Edit
                  </.link>
                  <button 
                    phx-click="delete_npc" 
                    phx-value-id={npc.id}
                    data-confirm="Are you sure you want to delete this NPC?"
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

  defp npc_type_color(type) do
    case type do
      "friendly" -> "bg-green-100 text-green-800"
      "hostile" -> "bg-red-100 text-red-800"
      "merchant" -> "bg-yellow-100 text-yellow-800"
      "quest_giver" -> "bg-purple-100 text-purple-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp ensure_tutorial_npcs_exist do
    tutorial_npcs = [
      %{
        name: "Goldie",
        description: "A friendly golden retriever with a wagging tail and bright, intelligent eyes. Goldie loves to greet adventurers and seems to understand more than most dogs.",
        npc_type: "friendly",
        level: 1,
        health: 50,
        max_health: 50,
        mana: 0,
        max_mana: 0,
        strength: 5,
        dexterity: 8,
        intelligence: 6,
        constitution: 7,
        experience_reward: 0,
        gold_reward: 0,
        faction: "neutral",
        aggression_level: 0,
        movement_pattern: "random",
        is_active: true,
        dialogue: "Woof! *wags tail enthusiastically*",
        location_x: 0,
        location_y: 0,
        location_z: 0
      },
      %{
        name: "Elder Thorne",
        description: "An ancient wizard with a long white beard and twinkling eyes. His robes shimmer with magical energy, and he carries a gnarled staff topped with a glowing crystal.",
        npc_type: "quest_giver",
        level: 50,
        health: 200,
        max_health: 200,
        mana: 500,
        max_mana: 500,
        strength: 8,
        dexterity: 6,
        intelligence: 20,
        constitution: 12,
        experience_reward: 0,
        gold_reward: 0,
        faction: "neutral",
        aggression_level: 0,
        movement_pattern: "stationary",
        is_active: true,
        dialogue: "Welcome, young adventurer! I have been expecting you. There are many mysteries in this realm that need solving.",
        location_x: 0,
        location_y: 1,
        location_z: 0
      },
      %{
        name: "Merchant Pip",
        description: "A cheerful halfling merchant with a round belly and a wide smile. His cart is filled with various goods, potions, and trinkets that catch the light.",
        npc_type: "merchant",
        level: 10,
        health: 80,
        max_health: 80,
        mana: 50,
        max_mana: 50,
        strength: 6,
        dexterity: 12,
        intelligence: 14,
        constitution: 10,
        experience_reward: 0,
        gold_reward: 0,
        faction: "neutral",
        aggression_level: 0,
        movement_pattern: "stationary",
        is_active: true,
        dialogue: "Welcome to Pip's Traveling Emporium! I've got the finest wares this side of the mountains. What can I get for you today?",
        location_x: -2,
        location_y: 1,
        location_z: 0
      },
      %{
        name: "Training Dummy",
        description: "A sturdy wooden training dummy wrapped in straw and leather. It bears the marks of countless practice sessions and stands ready for combat training.",
        npc_type: "neutral",
        level: 1,
        health: 100,
        max_health: 100,
        mana: 0,
        max_mana: 0,
        strength: 1,
        dexterity: 1,
        intelligence: 1,
        constitution: 15,
        experience_reward: 5,
        gold_reward: 0,
        faction: "neutral",
        aggression_level: 0,
        movement_pattern: "stationary",
        is_active: true,
        dialogue: "*The training dummy stands silently, ready to absorb your attacks*",
        location_x: 1,
        location_y: -1,
        location_z: 0
      }
    ]

    Enum.each(tutorial_npcs, fn npc_params ->
      case Npcs.get_npc_by_name(npc_params.name) do
        nil ->
          case Npcs.create_npc(npc_params) do
            {:ok, _npc} -> :ok
            {:error, _changeset} -> :error
          end
        
        existing_npc -> 
          # Ensure NPC is at correct tutorial location
          expected_x = npc_params.location_x
          expected_y = npc_params.location_y
          expected_z = npc_params.location_z
          
          if existing_npc.location_x != expected_x or 
             existing_npc.location_y != expected_y or 
             existing_npc.location_z != expected_z do
            existing_npc
            |> Ecto.Changeset.change(%{
              location_x: expected_x, 
              location_y: expected_y, 
              location_z: expected_z
            })
            |> Repo.update()
          end
          :ok
      end
    end)
  end
end

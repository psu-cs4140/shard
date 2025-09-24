defmodule ShardWeb.AdminLive.Quests do
  use ShardWeb, :live_view

  alias Shard.Quests
  alias Shard.Quests.Quest
  alias Shard.Npcs

  @impl true
  def mount(_params, _session, socket) do
    quests = Quests.list_quests_with_preloads()
    npcs = Npcs.list_npcs()
    
    {:ok, assign(socket, 
      quests: quests, 
      npcs: npcs,
      show_form: false,
      form_quest: nil,
      form_title: "Create Quest"
    )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Quests Administration")
    |> assign(:show_form, false)
  end

  defp apply_action(socket, :new, _params) do
    changeset = Quests.change_quest(%Quest{})
    socket
    |> assign(:page_title, "New Quest")
    |> assign(:show_form, true)
    |> assign(:form_quest, %Quest{})
    |> assign(:form_title, "Create Quest")
    |> assign(:changeset, changeset)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    quest = Quests.get_quest_with_preloads!(id)
    changeset = Quests.change_quest(quest)
    
    socket
    |> assign(:page_title, "Edit Quest")
    |> assign(:show_form, true)
    |> assign(:form_quest, quest)
    |> assign(:form_title, "Edit Quest")
    |> assign(:changeset, changeset)
  end

  @impl true
  def handle_event("edit_quest", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/quests/#{id}/edit")}
  end

  def handle_event("delete_quest", %{"id" => id}, socket) do
    quest = Quests.get_quest!(id)
    {:ok, _} = Quests.delete_quest(quest)
    
    quests = Quests.list_quests_with_preloads()
    
    {:noreply, 
      socket
      |> assign(:quests, quests)
      |> put_flash(:info, "Quest deleted successfully")
    }
  end

  def handle_event("cancel_form", _params, socket) do
    {:noreply, 
      socket
      |> assign(:show_form, false)
      |> push_patch(to: ~p"/admin/quests")
    }
  end

  def handle_event("save_quest", %{"quest" => quest_params}, socket) do
    case socket.assigns.form_quest.id do
      nil -> create_quest(socket, quest_params)
      _id -> update_quest(socket, quest_params)
    end
  end

  defp create_quest(socket, quest_params) do
    case Quests.create_quest(quest_params) do
      {:ok, _quest} ->
        quests = Quests.list_quests_with_preloads()
        
        {:noreply,
          socket
          |> assign(:quests, quests)
          |> assign(:show_form, false)
          |> put_flash(:info, "Quest created successfully")
          |> push_patch(to: ~p"/admin/quests")
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp update_quest(socket, quest_params) do
    case Quests.update_quest(socket.assigns.form_quest, quest_params) do
      {:ok, _quest} ->
        quests = Quests.list_quests_with_preloads()
        
        {:noreply,
          socket
          |> assign(:quests, quests)
          |> assign(:show_form, false)
          |> put_flash(:info, "Quest updated successfully")
          |> push_patch(to: ~p"/admin/quests")
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
        <h1 class="text-3xl font-bold">Quests Administration</h1>
        <.link 
          patch={~p"/admin/quests/new"}
          class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg inline-block"
        >
          + New Quest
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
              phx-submit="save_quest"
              id="quest-form"
            >
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <% form = to_form(@changeset) %>
                <.input field={form[:title]} label="Title" required />
                <.input field={form[:quest_type]} type="select" label="Type" 
                  options={[
                    {"Main", "main"},
                    {"Side", "side"}, 
                    {"Daily", "daily"},
                    {"Repeatable", "repeatable"}
                  ]} />
                
                <.input field={form[:difficulty]} type="select" label="Difficulty"
                  options={[
                    {"Easy", "easy"},
                    {"Normal", "normal"},
                    {"Hard", "hard"},
                    {"Epic", "epic"},
                    {"Legendary", "legendary"}
                  ]} />
                
                <.input field={form[:status]} type="select" label="Status"
                  options={[
                    {"Available", "available"},
                    {"In Progress", "in_progress"},
                    {"Completed", "completed"},
                    {"Failed", "failed"},
                    {"Locked", "locked"}
                  ]} />
                
                <.input field={form[:min_level]} type="number" label="Min Level" />
                <.input field={form[:max_level]} type="number" label="Max Level" />
                
                <.input field={form[:experience_reward]} type="number" label="Experience Reward" />
                <.input field={form[:gold_reward]} type="number" label="Gold Reward" />
                
                <.input field={form[:giver_npc_id]} type="select" label="Quest Giver NPC" 
                  options={[{"None", nil} | Enum.map(@npcs, &{&1.name, &1.id})]} />
                
                <.input field={form[:turn_in_npc_id]} type="select" label="Turn In NPC" 
                  options={[{"None", nil} | Enum.map(@npcs, &{&1.name, &1.id})]} />
                
                <.input field={form[:time_limit]} type="number" label="Time Limit (hours)" />
                <.input field={form[:cooldown_hours]} type="number" label="Cooldown Hours" />
                
                <.input field={form[:faction_requirement]} label="Faction Requirement" />
                <.input field={form[:location_hint]} label="Location Hint" />
                
                <.input field={form[:sort_order]} type="number" label="Sort Order" />
              </div>
              
              <.input field={form[:description]} type="textarea" label="Description" required />
              <.input field={form[:short_description]} label="Short Description" />
              
              <div class="flex items-center space-x-4">
                <.input field={form[:is_repeatable]} type="checkbox" label="Repeatable" />
                <.input field={form[:is_active]} type="checkbox" label="Active" />
              </div>
              
              <div class="flex justify-end space-x-2">
                <.link 
                  patch={~p"/admin/quests"}
                  class="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 inline-block"
                >
                  Cancel
                </.link>
                <button 
                  type="submit"
                  class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Save Quest
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
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Title</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Difficulty</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Level Range</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Rewards</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <%= for quest <- @quests do %>
              <tr>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm font-medium text-gray-900"><%= quest.title %></div>
                  <div class="text-sm text-gray-500"><%= String.slice(quest.short_description || quest.description || "", 0, 50) %><%= if String.length(quest.short_description || quest.description || "") > 50, do: "..." %></div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{quest_type_color(quest.quest_type)}"}>
                    <%= String.capitalize(quest.quest_type) %>
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{difficulty_color(quest.difficulty)}"}>
                    <%= String.capitalize(quest.difficulty) %>
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  <%= quest.min_level %><%= if quest.max_level, do: " - #{quest.max_level}", else: "+" %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  <%= if quest.experience_reward > 0, do: "#{quest.experience_reward} XP" %>
                  <%= if quest.gold_reward > 0, do: " #{quest.gold_reward} Gold" %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{status_color(quest.status)}"}>
                    <%= String.capitalize(String.replace(quest.status, "_", " ")) %>
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                  <.link 
                    patch={~p"/admin/quests/#{quest.id}/edit"}
                    class="text-indigo-600 hover:text-indigo-900 mr-3"
                  >
                    Edit
                  </.link>
                  <button 
                    phx-click="delete_quest" 
                    phx-value-id={quest.id}
                    data-confirm="Are you sure you want to delete this quest?"
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

  defp quest_type_color(type) do
    case type do
      "main" -> "bg-purple-100 text-purple-800"
      "side" -> "bg-blue-100 text-blue-800"
      "daily" -> "bg-green-100 text-green-800"
      "repeatable" -> "bg-yellow-100 text-yellow-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp difficulty_color(difficulty) do
    case difficulty do
      "easy" -> "bg-green-100 text-green-800"
      "normal" -> "bg-blue-100 text-blue-800"
      "hard" -> "bg-yellow-100 text-yellow-800"
      "epic" -> "bg-orange-100 text-orange-800"
      "legendary" -> "bg-red-100 text-red-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp status_color(status) do
    case status do
      "available" -> "bg-green-100 text-green-800"
      "in_progress" -> "bg-blue-100 text-blue-800"
      "completed" -> "bg-purple-100 text-purple-800"
      "failed" -> "bg-red-100 text-red-800"
      "locked" -> "bg-gray-100 text-gray-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end
end

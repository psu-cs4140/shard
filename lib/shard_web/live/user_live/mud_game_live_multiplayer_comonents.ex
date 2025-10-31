defmodule ShardWeb.UserLive.MudGameLiveMultiplayerComponents do
  use ShardWeb, :live_view

  # Online players component
  def online_players(assigns) do
    ~H"""
    <div class="bg-gray-700 rounded-lg p-4 mb-4">
      <h3 class="text-lg font-semibold mb-3 text-green-400">Online Players</h3>
      <div class="space-y-2 max-h-32 overflow-y-auto">
        <%= if Enum.empty?(@online_players) do %>
          <div class="text-gray-400 text-sm">No other players online</div>
        <% else %>
          <%= for player <- @online_players do %>
            <div class="flex items-center justify-between bg-gray-600 rounded px-3 py-2">
              <div class="flex items-center space-x-2">
                <div class="w-2 h-2 bg-green-400 rounded-full"></div>
                <span class="text-sm font-medium">{player.name}</span>
              </div>
              <div class="text-xs text-gray-300">
                Lvl {player.level}
              </div>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  # Chat component
  def chat(assigns) do
    ~H"""
    <div class="flex flex-col h-full min-h-0">
      <!-- Chat Messages -->
      <div
        class="flex-1 bg-black p-4 font-mono text-sm overflow-y-auto border border-gray-600 rounded min-h-0"
        id="chat-messages"
        phx-hook="ChatScroll"
      >
        <div class="whitespace-pre-wrap">
          <%= for message <- @chat_state.messages do %>
            <div class="text-blue-400 leading-tight">{message}</div>
          <% end %>
        </div>
      </div>
      
    <!-- Chat Input -->
      <form phx-submit="submit_chat" class="mt-4 flex-shrink-0">
        <div class="flex">
          <input
            type="text"
            name="chat[text]"
            value={@chat_state.current_message}
            phx-change="update_chat"
            placeholder="Type your message..."
            class="flex-1 px-3 py-2 bg-gray-800 border border-gray-600 rounded-l text-white placeholder-gray-400 focus:outline-none focus:border-blue-500"
            autocomplete="off"
          />
          <button
            type="submit"
            class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-r transition-colors"
          >
            Send
          </button>
        </div>
      </form>
    </div>
    """
  end
end

defmodule ShardWeb.UserLive.MudGameLiveMultiplayerComponents do
  use ShardWeb, :live_view

  # Online players component
  def online_players(assigns) do
    ~H"""
    <div class="bg-gray-700 rounded-lg p-4 mb-4">
      <h3 class="text-lg font-semibold mb-3 text-green-400">Online Players</h3>
      <div class="space-y-2 max-h-32 overflow-y-auto">
        <!-- Always show current player first -->
        <div class="flex items-center justify-between bg-gray-600 rounded px-3 py-2 border-l-4 border-blue-400">
          <div class="flex items-center space-x-2">
            <div class="w-2 h-2 bg-green-400 rounded-full"></div>
            <span class="text-sm font-medium">{@character_name} (You)</span>
          </div>
          <div class="text-xs text-gray-300">
            Lvl {@current_player_level}
          </div>
        </div>

    <!-- Show other players -->
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

        <%= if Enum.empty?(@online_players) do %>
          <div class="text-gray-400 text-sm">No other players online</div>
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
        <div class="space-y-1">
          <%= for message <- @chat_state.messages do %>
            <div class={get_message_class(message) <> " whitespace-pre-wrap break-words"}>
              {format_message_text(message)}
            </div>
          <% end %>
        </div>
      </div>

    <!-- Chat Input -->
      <form phx-submit="submit_chat" class="mt-4 flex-shrink-0">
        <div class="flex">
          <textarea
            name="chat[text]"
            phx-change="update_chat"
            placeholder="Type your message..."
            class="flex-1 px-3 py-2 bg-gray-800 border border-gray-600 rounded-l text-white placeholder-gray-400 focus:outline-none focus:border-blue-500"
            autocomplete="off"
          >{Phoenix.HTML.html_escape(@chat_state.current_message)}</textarea>
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

  # Helper functions for chat message formatting
  defp get_message_class(message) do
    # Extract character_name and character_id from message
    case Regex.run(~r/\[.*?\] (.*?):(\d+):/, message, capture: :all_but_first) do
      [character_name, character_id] ->
        # Generate consistent color based on character name or ID
        color_class = generate_color_class(character_name, character_id)
        "font-mono text-sm #{color_class}"

      _ ->
        "font-mono text-sm text-blue-400"
    end
  end

  defp format_message_text(message) do
    # Remove the character_id from the displayed message
    case Regex.run(~r/(\[.*?\] .*?):\d+:(.*)/, message, capture: :all_but_first) do
      [prefix, text] ->
        "#{prefix}: #{text}"

      _ ->
        message
    end
  end

  defp generate_color_class("BOB", _character_id) do
    # Special animated rainbow color for characters named "BOB"
    "text-transparent bg-clip-text bg-gradient-to-r from-red-500 via-yellow-500 via-green-500 via-blue-500 to-purple-500 animate-rainbow"
  end

  defp generate_color_class(_character_name, character_id) do
    # Generate a hash of the character identifier (ID) to determine color
    hash = :erlang.phash2(character_id, 1000)

    # Define a set of distinct colors
    colors = [
      "text-blue-400",
      "text-green-400",
      "text-yellow-400",
      "text-red-400",
      "text-purple-400",
      "text-pink-400",
      "text-indigo-400",
      "text-teal-400",
      "text-orange-400",
      "text-cyan-400"
    ]

    # Select color based on hash
    Enum.at(colors, rem(hash, length(colors)))
  end
end

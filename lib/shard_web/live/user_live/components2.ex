defmodule ShardWeb.UserLive.Components2 do
  use ShardWeb, :live_view
  import ShardWeb.UserLive.MinimapComponents

  # ───────────── Terminal ─────────────
  attr :terminal_state, :map, required: true

  def terminal(assigns) do
    ~H"""
    <div class="flex flex-col h-full bg-black rounded-lg border border-gray-600">
      <!-- Terminal Header -->
      <div class="bg-gray-800 px-4 py-2 rounded-t-lg border-b border-gray-600">
        <h2 class="text-green-400 font-mono text-sm">MUD Terminal</h2>
      </div>

    <!-- Terminal Output -->
      <div
        class="flex-1 p-4 overflow-y-auto font-mono text-sm text-green-400 bg-black"
        id="terminal-output"
        phx-hook="TerminalScroll"
      >
        <%= for line <- @terminal_state.output do %>
          <div class="whitespace-pre-wrap">{line}</div>
        <% end %>
      </div>

    <!-- Command Input -->
      <div class="p-4 border-t border-gray-600 bg-gray-900 rounded-b-lg">
        <.form
          for={%{}}
          as={:command}
          phx-submit="submit_command"
          phx-change="update_command"
          class="flex"
        >
          <span class="text-green-400 font-mono mr-2">></span>
          <input
            type="text"
            name="command[text]"
            value={@terminal_state.current_command}
            placeholder="Enter command..."
            class="flex-1 bg-transparent border-none text-green-400 font-mono focus:ring-0 focus:outline-none p-0"
            autocomplete="off"
          />
        </.form>
      </div>
    </div>
    """
  end

  # ───────────── Player Stats ─────────────
  attr :stats, :map, required: true
  attr :hotbar, :map, default: %{}

  def player_stats(assigns) do
    ~H"""
    <div class="bg-gray-700 rounded-lg p-4 shadow-xl">
      <h2 class="text-xl font-semibold mb-4 text-center">Player Stats</h2>

    <!-- Health Bar -->
      <div class="mb-3">
        <div class="flex justify-between text-sm mb-1">
          <span class="text-red-400">Health</span>
          <span class="text-gray-300">{@stats.health}/{@stats.max_health}</span>
        </div>
        <div class="w-full bg-gray-600 rounded-full h-3">
          <div
            class="bg-red-500 h-3 rounded-full transition-all duration-300"
            style={"width: #{(@stats.health / @stats.max_health * 100)}%"}
          />
        </div>
      </div>

    <!-- Stamina Bar -->
      <div class="mb-3">
        <div class="flex justify-between text-sm mb-1">
          <span class="text-yellow-400">Stamina</span>
          <span class="text-gray-300">{@stats.stamina}/{@stats.max_stamina}</span>
        </div>
        <div class="w-full bg-gray-600 rounded-full h-3">
          <div
            class="bg-yellow-500 h-3 rounded-full transition-all duration-300"
            style={"width: #{(@stats.stamina / @stats.max_stamina * 100)}%"}
          />
        </div>
      </div>

    <!-- Mana Bar -->
      <div class="mb-3">
        <div class="flex justify-between text-sm mb-1">
          <span class="text-blue-400">Mana</span>
          <span class="text-gray-300">{@stats.mana}/{@stats.max_mana}</span>
        </div>
        <div class="w-full bg-gray-600 rounded-full h-3">
          <div
            class="bg-blue-500 h-3 rounded-full transition-all duration-300"
            style={"width: #{(@stats.mana / @stats.max_mana * 100)}%"}
          />
        </div>
      </div>

    <!-- Hotbar -->
      <div class="mt-4">
        <h3 class="text-lg font-semibold mb-2 text-center">Hotbar</h3>
        <div class="flex justify-center space-x-2">
          <%= for slot_num <- 1..5 do %>
            <.hotbar_slot
              slot_data={Map.get(@hotbar, String.to_atom("slot_#{slot_num}"))}
              slot_number={slot_num}
            />
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # ───────────── Control Button ─────────────
  attr :click, Phoenix.LiveView.JS, default: nil
  attr :value, :any, default: nil
  attr :icon, :string, required: true
  attr :text, :string, required: true

  def control_button(assigns) do
    ~H"""
    <button
      phx-click={@click}
      phx-value-modal={@value}
      class="w-full flex items-center justify-start gap-3 p-3 bg-gray-700 hover:bg-gray-600 rounded-lg transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
    >
      <.icon name={@icon} class="w-5 h-5" />
      <span>{@text}</span>
    </button>
    """
  end

  # ───────────── Hotbar Slot ─────────────
  attr :slot_data, :map, default: nil
  attr :slot_number, :integer, required: true

  def hotbar_slot(assigns) do
    ~H"""
    <button
      phx-click={if @slot_data, do: "use_hotbar_item", else: nil}
      phx-value-slot={@slot_number}
      class={"w-12 h-12 bg-gray-600 border-2 border-gray-500 rounded-lg flex items-center justify-center relative transition-colors #{if @slot_data, do: "hover:border-gray-400 cursor-pointer", else: "cursor-default"}"}
      disabled={is_nil(@slot_data)}
    >
      <!-- Slot number -->
      <!-- <span class="absolute top-0 left-1 text-xs text-gray-400">{@slot_number}</span> -->

    <!-- Item content -->
      <%= if @slot_data do %>
        <div class="text-center">
          <%= case @slot_data.type do %>
            <% "weapon" -> %>
              <.icon name="hero-sword" class="w-6 h-6 text-red-400" />
            <% "consumable" -> %>
              <.icon name="hero-beaker" class="w-6 h-6 text-green-400" />
            <% "armor" -> %>
              <.icon name="hero-shield-check" class="w-6 h-6 text-blue-400" />
            <% _ -> %>
              <.icon name="hero-cube" class="w-6 h-6 text-gray-400" />
          <% end %>
        </div>
        <!-- Tooltip -->
        <div class="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-2 py-1 bg-gray-800 text-white text-xs rounded opacity-0 hover:opacity-100 transition-opacity pointer-events-none z-10">
          <div class="font-semibold">{@slot_data.name}</div>
          <%= if @slot_data[:effect] do %>
            <div class="text-xs text-gray-300">{@slot_data.effect}</div>
          <% end %>
          <div class="text-xs text-yellow-300">Click to use</div>
        </div>
      <% else %>
        <!-- Empty slot -->
        <div class="w-8 h-8 border border-dashed border-gray-500 rounded"></div>
      <% end %>
    </button>
    """
  end

  # ───────────── Player Marker (single definition) ─────────────
  attr :position, :any, required: true
  attr :bounds, :any, required: true
  attr :scale_factor, :any, required: true

  def player_marker(assigns) do
    {x_pos, y_pos} =
      calculate_minimap_position(
        assigns.position,
        assigns.bounds,
        assigns.scale_factor
      )

    assigns = assign(assigns, x_pos: x_pos, y_pos: y_pos)

    ~H"""
    <circle
      cx={@x_pos}
      cy={@y_pos}
      r="8"
      fill="#ef4444"
      stroke="#ffffff"
      stroke-width="2"
      opacity="0.9"
    >
      <title>Player at {format_position(@position)} (no room)</title>
    </circle>
    """
  end

  # ───────────── Helpers ─────────────
  defp format_position({x, y}), do: "{#{x}, #{y}}"
end

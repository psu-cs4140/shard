defmodule ShardWeb.Layouts do
  use ShardWeb, :html

  # Keep using any templates in lib/shard_web/components/layouts/*.heex
  embed_templates "layouts/*"

  # <Layouts.app> is a function component used by many pages
  attr :flash, :map, default: %{}
  attr :current_scope, :any, default: nil
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="navbar bg-base-200 px-4">
      <div class="flex-1">
        <.link href={~p"/"} class="btn btn-ghost text-lg font-semibold">Shard</.link>
      </div>

      <nav class="flex-none space-x-2">
        <.link href={~p"/music"} class="btn btn-ghost">Music</.link>

        <%= if match?(%{user: %{}}, @current_scope) do %>
          <span class="text-sm opacity-70">{@current_scope.user.email}</span>
          <.link href={~p"/users/settings"} class="btn btn-ghost">Settings</.link>
          <%= if @current_scope.user.admin do %>
            <.link href={~p"/admin"} class="btn btn-ghost">Admin</.link>
          <% end %>
          <!-- method must be a string -->
          <.link href={~p"/users/log_out"} method="delete" class="btn">Log out</.link>
        <% else %>
          <.link navigate={~p"/users/register"} class="btn btn-ghost">Register</.link>
          <.link navigate={~p"/users/log_in"} class="btn">Log in</.link>
        <% end %>
      </nav>
    </header>

    <main class="container mx-auto p-4">
      <%= if msg = Phoenix.Flash.get(@flash, :info) do %>
        <div id="flash-info" class="toast toast-top toast-end z-50">
          <div class="alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap alert-info">
            <span class="hero-information-circle size-5 shrink-0"></span>
            <div>
              <p>{msg}</p>
            </div>
          </div>
        </div>
      <% end %>

      <%= if msg = Phoenix.Flash.get(@flash, :error) do %>
        <div id="flash-error" class="toast toast-top toast-end z-50">
          <div class="alert w-80 sm:w-96 max-w-80 sm-max-w-96 text-wrap alert-error">
            <span class="hero-exclamation-circle size-5 shrink-0"></span>
            <div>
              <p>{msg}</p>
            </div>
          </div>
        </div>
      <% end %>

      {render_slot(@inner_block)}
    </main>

    <footer class="mt-8 border-t border-base-300 bg-base-200/50">
      <div class="container mx-auto px-4 py-3 text-sm text-base-content/60">
        <span>Some background music may be licensed; see </span>
        <.link href={~p"/credits"} class="link link-hover">Credits</.link>
        <span class="mx-1">·</span>
        <span>
          Example track in dev: “Sneaky Snitch” — Kevin MacLeod (incompetech.com), CC BY 3.0.
        </span>
      </div>
    </footer>
    """
  end
end

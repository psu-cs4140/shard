defmodule ShardWeb.PreferencesLive do
  use ShardWeb, :live_view
  alias Shard.Users
  alias Phoenix.Component
  import Phoenix.LiveView, only: [redirect: 2, put_flash: 3]

  @impl true
  def mount(_params, _session, socket) do
    case current_user(socket) do
      nil ->
        {:halt, redirect(socket, to: ~p"/users/log_in")}

      user ->
        form = Component.to_form(Users.change_user_preferences(user))
        {:ok, assign(socket, music_form: form, current_user: user)}
    end
  end

  @impl true
  def handle_event("validate", %{"user" => params}, socket) do
    user = socket.assigns.current_user || current_user(socket)
    cs = Users.change_user_preferences(user, params)
    {:noreply, assign(socket, :music_form, Component.to_form(%{cs | action: :validate}))}
  end

  @impl true
  def handle_event("save", %{"user" => params}, socket) do
    user = socket.assigns.current_user || current_user(socket)

    case Users.update_user_preferences(user, params) do
      {:ok, user} ->
        form = Component.to_form(Users.change_user_preferences(user))
        {:noreply,
         socket
         |> put_flash(:info, "Preferences updated")
         |> assign(current_user: user, music_form: form)}

      {:error, cs} ->
        {:noreply, assign(socket, :music_form, Component.to_form(cs))}
    end
  end

  # — Helpers —

  defp current_user(socket) do
    socket.assigns[:current_user] ||
      (socket.assigns[:current_scope] && socket.assigns.current_scope.user)
  end
end

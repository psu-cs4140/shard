defmodule ShardWeb.UserLive.Settings do
  use ShardWeb, :live_view

  # Safe even if also applied via live_session in the router
  on_mount {ShardWeb.UserAuth, :require_sudo_mode}

  alias Shard.Users

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="text-center">
        <.header>
          Account Settings
          <:subtitle>Manage your account email address and password settings</:subtitle>
        </.header>
      </div>
      
    <!-- Email -->
      <.form for={@email_form} id="email_form" phx-submit="update_email" phx-change="validate_email">
        <.input
          field={@email_form[:email]}
          type="email"
          label="Email"
          autocomplete="username"
          required
        />
        <.button variant="primary" phx-disable-with="Changing...">Change Email</.button>
      </.form>

      <div class="divider" />
      
    <!-- Password (fully handled in LiveView) -->
      <.form
        for={@password_form}
        id="password_form"
        phx-change="validate_password"
        phx-submit="update_password"
      >
        <input
          name={@password_form[:email].name}
          type="hidden"
          id="hidden_user_email"
          autocomplete="username"
          value={@current_email}
        />
        <.input
          field={@password_form[:password]}
          type="password"
          label="New password"
          autocomplete="new-password"
          required
        />
        <.input
          field={@password_form[:password_confirmation]}
          type="password"
          label="Confirm new password"
          autocomplete="new-password"
        />
        <.button variant="primary" phx-disable-with="Saving...">
          Save Password
        </.button>
      </.form>
      
    <!-- Preferences -->
      <div class="divider" />
      <.header>
        Preferences
        <:subtitle>Toggle gameplay and UI features</:subtitle>
      </.header>

      <.form for={@prefs_form} id="prefs_form" phx-change="validate_prefs" phx-submit="update_prefs">
        <.input field={@prefs_form[:music_enabled]} type="checkbox" label="Enable music" />
        <.button variant="primary" phx-disable-with="Saving...">Save Preferences</.button>
      </.form>
      
    <!-- Admin -->
      <%= if @current_user && !@current_user.admin do %>
        <div class="divider" />
        <div class="mt-6">
          <.header>
            Admin Privileges
            <:subtitle>Request admin access for your account</:subtitle>
          </.header>
          <.button phx-click="make_admin" phx-disable-with="Processing..." class="btn btn-warning">
            Make My Account Admin
          </.button>
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  # Handle /users/settings/confirm-email/:token (from router live route)
  @impl true
  def mount(%{"token" => token}, _session, socket) do
    user = socket.assigns.current_user || get_in(socket.assigns, [:current_scope, :user])

    socket =
      case Users.update_user_email(user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "Email changed successfully.")

        {:error, _} ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  # Normal Settings page
  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user || get_in(socket.assigns, [:current_scope, :user])

    # start with blank forms populated with the current email
    email_changeset = Users.change_user_email(user, %{})
    password_form = to_form(%{"email" => user.email}, as: "user")
    prefs_changeset = Users.change_user_preferences(user, %{})

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, password_form)
      |> assign(:prefs_form, to_form(prefs_changeset))
      |> assign(:current_user, user)

    {:ok, socket}
  end

  # Email
  @impl true
  def handle_event("validate_email", %{"user" => attrs}, socket) do
    user = socket.assigns.current_user || get_in(socket.assigns, [:current_scope, :user])

    email_form =
      user
      |> Users.change_user_email(attrs)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  @impl true
  def handle_event("update_email", %{"user" => attrs}, socket) do
    user = socket.assigns.current_user || get_in(socket.assigns, [:current_scope, :user])
    true = Users.sudo_mode?(user)

    case Users.change_user_email(user, attrs) do
      %{valid?: true} = changeset ->
        Users.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        {:noreply,
         put_flash(
           socket,
           :info,
           "A link to confirm your email change has been sent to the new address."
         )}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end

  # Password
  @impl true
  def handle_event("validate_password", %{"user" => attrs}, socket) do
    user = socket.assigns.current_user || get_in(socket.assigns, [:current_scope, :user])

    cs = Shard.Users.User.password_changeset(user, attrs)
    {:noreply, assign(socket, :password_form, to_form(%{cs | action: :validate}))}
  end

  @impl true
  def handle_event("update_password", %{"user" => attrs}, socket) do
    user = socket.assigns.current_user || get_in(socket.assigns, [:current_scope, :user])
    true = Users.sudo_mode?(user)

    case Users.update_user_password(user, attrs) do
      {:ok, updated} ->
        new_scope = %{socket.assigns.current_scope | user: updated}

        {:noreply,
         socket
         |> assign(
           current_scope: new_scope,
           current_user: updated,
           password_form: to_form(%{"email" => updated.email}, as: "user")
         )
         |> put_flash(:info, "Password updated successfully.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :password_form, to_form(changeset, action: :insert))}
    end
  end

  # Preferences
  @impl true
  def handle_event("validate_prefs", %{"user" => params}, socket) do
    user = socket.assigns.current_user || get_in(socket.assigns, [:current_scope, :user])

    form =
      user
      |> Users.change_user_preferences(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, prefs_form: form)}
  end

  @impl true
  def handle_event("update_prefs", %{"user" => params}, socket) do
    user = socket.assigns.current_user || get_in(socket.assigns, [:current_scope, :user])

    case Users.update_user_preferences(user, params) do
      {:ok, updated} ->
        new_scope = %{socket.assigns.current_scope | user: updated}

        {:noreply,
         socket
         |> assign(
           current_scope: new_scope,
           current_user: updated,
           prefs_form: to_form(Users.change_user_preferences(updated, %{}))
         )
         |> put_flash(:info, "Preferences saved.")}

      {:error, changeset} ->
        {:noreply, assign(socket, prefs_form: to_form(changeset, action: :insert))}
    end
  end

  # Admin
  @impl true
  def handle_event("make_admin", _params, socket) do
    user = socket.assigns.current_user || get_in(socket.assigns, [:current_scope, :user])
    true = Users.sudo_mode?(user)

    case Users.grant_admin(user) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> assign(
           current_scope: %{socket.assigns.current_scope | user: updated},
           current_user: updated
         )
         |> put_flash(:info, "Admin privileges granted successfully.")
         |> push_navigate(to: ~p"/users/settings")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Unable to grant admin privileges. Please try again.")
         |> push_navigate(to: ~p"/users/settings")}
    end
  end
end

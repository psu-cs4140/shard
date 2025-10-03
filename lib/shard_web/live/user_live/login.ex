defmodule ShardWeb.UserLive.Login do
  use ShardWeb, :live_view

  alias Shard.Users

  # Compile HEEx templates from lib/shard_web/live/user_live/login/*
  embed_templates "login/*"

  # Exact string expected by the test suite
  @reauth_message "You need to reauthenticate"

  @impl true
  def render(assigns), do: ~H[<.login {assigns} />]

  @impl true
  def mount(params, _session, socket) do
    # Prefill email in this order:
    # 1) explicit query param (?email=...) — used by some flows/tests
    # 2) currently-signed-in user
    # 3) legacy @current_scope.user
    email =
      params["email"] ||
        get_in(socket.assigns, [:current_user, Access.key(:email)]) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)]) ||
        ""

    # Reauth when the query flag is present (true/1/yes),
    # OR when we were redirected here from sudo-mode with the specific flash.
    reauth? =
      params["reauth"] in ["true", "1", "yes", true] or
        Phoenix.Flash.get(socket.assigns[:flash] || %{}, :error) ==
          "You must re-authenticate to access this page."

    form = to_form(%{"email" => email}, as: "user")

    {:ok,
     socket
     |> assign(
       form: form,
       trigger_submit: false,
       reauth: reauth?,
       reauth_message: @reauth_message
     )}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  @impl true
  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Users.get_user_by_email(email) do
      Users.deliver_login_instructions(
        user,
        &url(~p"/users/log_in?token=#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log_in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:shard, Shard.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end

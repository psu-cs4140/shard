defmodule ShardWeb.UserAuth do
  @moduledoc """
  Authentication helpers for controllers and LiveViews.
  """

  # Enable ~p verified routes in this plain module
  use ShardWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2, put_flash: 3, fetch_flash: 1, current_path: 1]
  alias Phoenix.Controller, as: PController
  alias Phoenix.Component, as: PC
  alias Phoenix.LiveView

  alias Shard.Users
  alias Shard.Users.{User, Scope}
  alias ShardWeb.Endpoint

  @remember_me_cookie "_shard_web_user_remember_me"
  # Signed cookie, 14 days, SameSite=Lax, HttpOnly
  @remember_me_opts [sign: true, max_age: 60 * 60 * 24 * 14, same_site: "Lax", http_only: true]

  # ======================================================================
  # Controller plugs
  # ======================================================================

  @doc """
  Assigns `:current_scope` and `:current_user` from session token or signed cookie.

  If authenticating via cookie, issues a fresh session token and cookie.
  """
  def fetch_current_scope_for_user(conn, _opts) do
    conn = conn |> fetch_session() |> fetch_cookies(signed: [@remember_me_cookie])

    case get_session(conn, :user_token) do
      token when is_binary(token) ->
        case normalize_user_lookup(Users.get_user_by_session_token(token)) do
          {:ok, user, meta} ->
            user = maybe_put_authenticated_at(user, meta)

            conn
            |> maybe_put_live_socket_id(token)
            |> assign_current(user)

          :error ->
            assign_guest(conn)
        end

      _ ->
        case conn.cookies[@remember_me_cookie] do
          cookie_token when is_binary(cookie_token) ->
            case normalize_user_lookup(Users.get_user_by_session_token(cookie_token)) do
              {:ok, user, meta} ->
                user = maybe_put_authenticated_at(user, meta)
                token = Users.generate_user_session_token(user)

                conn
                |> renew_session_preserving_return_to(clear?: true)
                |> put_session(:user_token, token)
                |> put_session(:user_remember_me, true)
                |> maybe_put_live_socket_id(token)
                |> PController.put_resp_cookie(@remember_me_cookie, token, @remember_me_opts)
                |> assign_current(user)

              :error ->
                assign_guest(conn)
            end

          _ ->
            assign_guest(conn)
        end
    end
  end

  defp maybe_put_live_socket_id(conn, token),
    do: put_session(conn, :live_socket_id, "users_sessions:#{Base.url_encode64(token)}")

  defp assign_current(conn, %User{} = user) do
    scope =
      if function_exported?(Scope, :for_user, 1),
        do: Scope.for_user(user),
        else: %Scope{user: user}

    conn
    |> Plug.Conn.assign(:current_scope, scope)
    |> Plug.Conn.assign(:current_user, user)
  end

  defp assign_guest(conn) do
    conn
    |> Plug.Conn.assign(:current_scope, nil)
    |> Plug.Conn.assign(:current_user, nil)
  end

  @doc """
  Controller guard: requires a logged-in user or redirects to /users/log_in.

  Exact flash required by tests: "You must log in to access this page."
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_scope] do
      conn
    else
      conn
      |> fetch_flash()
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/users/log_in")
      |> halt()
    end
  end

  defp maybe_store_return_to(%Plug.Conn{method: "GET"} = conn),
    do: put_session(conn, :user_return_to, current_path(conn))

  defp maybe_store_return_to(conn), do: conn

  # ======================================================================
  # Login / Logout
  # ======================================================================

  @doc """
  Log in and redirect.

  * Keeps the session when re-authing the same user; clears it when switching users.
  * Sets `:user_remember_me` and writes a signed cookie when requested or previously set.
  * Redirects to `:user_return_to` if present; otherwise:
      - `/users/settings` if this is a re-auth of the same user,
      - `/` for a regular login.
  """
  def log_in_user(conn, %User{} = user, params \\ %{}) do
    requested = Map.get(params, "remember_me", "false") in [true, "true", "on", "1"]
    prev = get_session(conn, :user_remember_me) == true
    remember = requested or prev

    same_user? =
      case conn.assigns do
        %{current_scope: %Scope{user: %User{id: id}}} -> id == user.id
        _ -> false
      end

    token = Users.generate_user_session_token(user)

    conn =
      conn
      |> renew_session_preserving_return_to(clear?: not same_user?)
      |> put_session(:user_token, token)
      |> put_session(:user_remember_me, remember)
      |> put_session(:authenticated_at, now_ndt())
      |> maybe_put_live_socket_id(token)

    conn =
      if remember do
        PController.put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_opts)
      else
        delete_resp_cookie(conn, @remember_me_cookie)
      end

    to =
      get_session(conn, :user_return_to) || if(same_user?, do: ~p"/users/settings", else: ~p"/")

    redirect(conn, to: to)
  end

  @doc """
  Log out: revoke token, broadcast disconnect, clear session & cookie, redirect home.
  """
  def log_out_user(conn) do
    if token = get_session(conn, :user_token) do
      Users.delete_user_session_token(token)

      if lsid = get_session(conn, :live_socket_id) do
        Endpoint.broadcast(lsid, "disconnect", %{})
      end
    end

    conn
    |> renew_session_preserving_return_to(clear?: true)
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  defp renew_session_preserving_return_to(conn, opts \\ []) do
    clear? = Keyword.get(opts, :clear?, true)
    return_to = get_session(conn, :user_return_to)

    conn =
      conn
      |> configure_session(renew: true)
      |> (fn c -> if clear?, do: clear_session(c), else: c end).()

    if return_to, do: put_session(conn, :user_return_to, return_to), else: conn
  end

  @doc """
  Broadcast \"disconnect\" for each token (used to kill LiveView sessions).
  """
  def disconnect_sessions(tokens) when is_list(tokens) do
    for %{token: token} <- tokens, is_binary(token) do
      Endpoint.broadcast("users_sessions:#{Base.url_encode64(token)}", "disconnect", %{})
    end

    :ok
  end

  # ======================================================================
  # LiveView on_mount hooks
  # ======================================================================

  # Users.get_user_by_session_token/1 may return:
  #   - {%User{}, %SomeMeta{}}
  #   - {%User{}, inserted_at :: DateTime}
  #   - %User{}
  #   - nil
  defp normalize_user_lookup({%User{} = u, %_{} = meta}), do: {:ok, u, meta}

  defp normalize_user_lookup({%User{} = u, inserted_at}) when is_struct(inserted_at, DateTime),
    do: {:ok, u, %{inserted_at: inserted_at}}

  defp normalize_user_lookup(%User{} = u), do: {:ok, u, %{}}
  defp normalize_user_lookup(_), do: :error

  defp maybe_put_authenticated_at(%User{} = user, meta) do
    # Prefer explicit authenticated_at; otherwise use inserted_at if provided.
    case Map.get(meta, :authenticated_at) || Map.get(meta, :inserted_at) do
      %DateTime{} = dt -> %{user | authenticated_at: dt}
      _ -> user
    end
  end

  @doc """
  Assign `:current_user` / `:current_scope` (or nil) without redirecting.
  """
  def on_mount(:mount_current_scope, _params, session, socket) do
    socket = ensure_flash(socket)

    case Map.get(session, "user_token") do
      token when is_binary(token) ->
        case normalize_user_lookup(Users.get_user_by_session_token(token)) do
          {:ok, user, meta} ->
            user = maybe_put_authenticated_at(user, meta)

            {:cont,
             socket
             |> PC.assign(:current_scope, Scope.for_user(user))
             |> PC.assign(:current_user, user)}

          :error ->
            {:cont, socket |> PC.assign(:current_scope, nil) |> PC.assign(:current_user, nil)}
        end

      _ ->
        {:cont, socket |> PC.assign(:current_scope, nil) |> PC.assign(:current_user, nil)}
    end
  end

  @doc """
  Require a logged-in user; else redirect to /users/log_in with exact flash.
  """
  def on_mount(:require_authenticated, _params, session, socket) do
    socket = ensure_flash(socket)

    case Map.get(session, "user_token") do
      token when is_binary(token) ->
        case normalize_user_lookup(Users.get_user_by_session_token(token)) do
          {:ok, user, meta} ->
            user = maybe_put_authenticated_at(user, meta)

            {:cont,
             socket
             |> PC.assign(:current_scope, Scope.for_user(user))
             |> PC.assign(:current_user, user)}

          :error ->
            {:halt,
             socket
             |> PC.assign(:current_scope, nil)
             |> LiveView.put_flash(:error, "You must log in to access this page.")
             |> LiveView.redirect(to: ~p"/users/log_in")}
        end

      _ ->
        {:halt,
         socket
         |> PC.assign(:current_scope, nil)
         |> LiveView.put_flash(:error, "You must log in to access this page.")
         |> LiveView.redirect(to: ~p"/users/log_in")}
    end
  end

  @fresh_seconds 10 * 60
  @doc """
  Require sudo mode (fresh auth ≤ 10 minutes).
  Redirect must include `?reauth=true` (tests expect this).
  """
  def on_mount(:require_sudo_mode, _params, session, socket) do
    socket = ensure_flash(socket)

    case Map.get(session, "user_token") do
      token when is_binary(token) ->
        case normalize_user_lookup(Users.get_user_by_session_token(token)) do
          {:ok, user, _meta} ->
            fresh? = fresh_auth?(session["authenticated_at"] || user.authenticated_at)

            if fresh? do
              {:cont,
               socket
               |> PC.assign(:current_scope, Scope.for_user(user))
               |> PC.assign(:current_user, user)}
            else
              {:halt,
               socket
               |> LiveView.put_flash(:error, "You must re-authenticate to access this page.")
               |> LiveView.redirect(to: ~p"/users/log_in?reauth=true")}
            end

          :error ->
            {:halt,
             socket
             |> LiveView.put_flash(:error, "You must re-authenticate to access this page.")
             |> LiveView.redirect(to: ~p"/users/log_in?reauth=true")}
        end

      _ ->
        {:halt,
         socket
         |> LiveView.put_flash(:error, "You must re-authenticate to access this page.")
         |> LiveView.redirect(to: ~p"/users/log_in?reauth=true")}
    end
  end

  @doc """
  Redirect away from public auth pages if already logged in, except when `reauth=true`.
  Sends logged-in users to `/users/settings` (team/test convention).
  """
  def on_mount(:redirect_if_user_is_authenticated, params, _session, socket) do
    socket = ensure_flash(socket)
    reauth? = Map.get(params, "reauth") in ["true", true, "1", "yes"]

    current? =
      match?(%{current_user: %User{}}, socket.assigns) or
        match?(%{current_scope: %Scope{user: %User{}}}, socket.assigns)

    if current? and not reauth? do
      {:halt, LiveView.redirect(socket, to: ~p"/users/settings")}
    else
      {:cont, socket}
    end
  end

  # In tests, a bare Socket may not have :flash; ensure it exists to avoid crashes
  def ensure_flash(%LiveView.Socket{} = socket) do
    if Map.has_key?(socket.assigns, :flash),
      do: socket,
      else: %{socket | assigns: Map.put(socket.assigns, :flash, %{})}
  end

  # ======================================================================
  # Helpers
  # ======================================================================

  defp now_ndt, do: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

  defp fresh_auth?(nil), do: false
  defp fresh_auth?(%NaiveDateTime{} = ts), do: NaiveDateTime.diff(now_ndt(), ts) <= @fresh_seconds
  defp fresh_auth?(%DateTime{} = ts), do: DateTime.diff(DateTime.utc_now(), ts) <= @fresh_seconds

  defp fresh_auth?(ts) when is_binary(ts) do
    case NaiveDateTime.from_iso8601(ts) do
      {:ok, ndt} -> fresh_auth?(ndt)
      _ -> false
    end
  end

  defp fresh_auth?(_), do: false
end

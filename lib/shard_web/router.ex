defmodule ShardWeb.Router do
  use ShardWeb, :router

  import ShardWeb.UserAuth

  # ───────────────────────── Admin guard ─────────────────────────
  defp ensure_admin(conn, _opts) do
    case conn.assigns[:current_scope] do
      %Shard.Users.Scope{user: %{admin: true}} ->
        conn

      _ ->
        conn
        |> Phoenix.Controller.put_flash(:error, "You must be an admin to access this page.")
        |> Phoenix.Controller.redirect(to: "/")
        |> Plug.Conn.halt()
    end
  end

  # ───────────────────────── Pipelines ─────────────────────────
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :fetch_live_flash
    plug :put_root_layout, html: {ShardWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :require_admin do
    plug :ensure_admin
  end

  # ───────────────────────── Public pages ─────────────────────────
  scope "/", ShardWeb do
    pipe_through :browser

    live "/", HomeLive, :index

    # Auth pages that should be reachable even if already logged-in (sudo mode, confirmation)
    live_session :auth_public,
      on_mount: [{ShardWeb.UserAuth, :mount_current_scope}] do
      live "/users/log-in/:token", UserLive.Confirmation, :new
      live "/users/log-in", UserLive.Login, :new
    end
  end

  # ───────────────────────── Auth: public (redirect if already authed) ─────────────────────────
  scope "/", ShardWeb do
    pipe_through [:browser]

    live_session :users_auth_public,
      on_mount: [
        {ShardWeb.UserAuth, :mount_current_scope},
        {ShardWeb.UserAuth, :redirect_if_user_is_authenticated}
      ] do
      live "/users/register", UserLive.Registration, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  # ───────────────────────── Auth: settings (requires auth; sudo for /users/settings) ─────────────────────────
  scope "/", ShardWeb do
    pipe_through [:browser, :require_authenticated_user]

    # Settings page requires fresh auth (sudo mode)
    live_session :users_settings,
      on_mount: [
        {ShardWeb.UserAuth, :mount_current_scope},
        {ShardWeb.UserAuth, :require_authenticated},
        {ShardWeb.UserAuth, :require_sudo_mode}
      ] do
      live "/users/settings", UserLive.Settings, :edit
    end

    # Email confirmation can skip sudo, still needs auth
    live_session :users_settings_email,
      on_mount: [
        {ShardWeb.UserAuth, :mount_current_scope},
        {ShardWeb.UserAuth, :require_authenticated}
      ] do
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    # Other authenticated gameplay routes
    live_session :app_authed,
      on_mount: [
        {ShardWeb.UserAuth, :mount_current_scope},
        {ShardWeb.UserAuth, :require_authenticated}
      ] do
      live "/characters", CharacterLive.Index, :index
      live "/characters/new", CharacterLive.New, :new
      live "/characters/:id", CharacterLive.Show, :show
      live "/inventory", InventoryLive.Index, :index
      live "/friends", FriendsLive.Index, :index
      live "/zones", ZoneSelectionLive, :index
      live "/play/:character_id", MudGameLive
      live "/marketplace", MarketplaceLive.Index, :index
      live "/achievements", AchievementsLive.Index, :index
      live "/gambling", GamblingLive.Index, :index
      live "/rewards", RewardsLive.Index, :index
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  # ───────────────────────── Admin ─────────────────────────
  scope "/admin", ShardWeb do
    pipe_through [:browser, :require_authenticated_user, :require_admin]

    live_session :admin,
      on_mount: [
        {ShardWeb.UserAuth, :mount_current_scope},
        {ShardWeb.UserAuth, :require_authenticated}
      ] do
      live "/", AdminLive.Index, :index
      live "/zones", AdminLive.Zones, :index
      live "/map", AdminLive.Map, :index

      live "/characters", AdminLive.Characters, :index
      live "/characters/new", AdminLive.Characters, :new
      live "/characters/:id", AdminLive.Characters, :show
      live "/characters/:id/edit", AdminLive.Characters, :edit

      live "/user_management", AdminLive.UserManagement, :index

      live "/npcs", AdminLive.Npcs, :index
      live "/npcs/new", AdminLive.Npcs, :new
      live "/npcs/:id/edit", AdminLive.Npcs, :edit

      live "/quests", AdminLive.Quests, :index
      live "/quests/new", AdminLive.Quests, :new
      live "/quests/:id/edit", AdminLive.Quests, :edit

      live "/items", AdminLive.Items, :index
      live "/items/new", AdminLive.Items, :new
      live "/items/:id", AdminLive.Items, :show
      live "/items/:id/edit", AdminLive.Items, :edit

      live "/monsters", AdminLive.Monsters, :index
      live "/monsters/new", AdminLive.Monsters, :new
      live "/monsters/:id", AdminLive.Monsters, :show
      live "/monsters/:id/edit", AdminLive.Monsters, :edit

      live "/spells", AdminLive.Spells, :index
      live "/spells/new", AdminLive.Spells, :new
      live "/spells/:id", AdminLive.Spells, :show
      live "/spells/:id/edit", AdminLive.Spells, :edit

      live "/spell_effects", AdminLive.SpellEffects, :index
      live "/spell_effects/new", AdminLive.SpellEffects, :new
      live "/spell_effects/:id", AdminLive.SpellEffects, :show
      live "/spell_effects/:id/edit", AdminLive.SpellEffects, :edit
    end
  end

  # ───────────────────────── Dev-only routes ─────────────────────────
  if Application.compile_env(:shard, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ShardWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

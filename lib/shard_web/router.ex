defmodule ShardWeb.Router do
  use ShardWeb, :router
import ShardWeb.UserAuth
  import Phoenix.LiveView.Router

  # ---------- Pipelines ----------
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ShardWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :redirect_if_authed do
    plug :redirect_if_user_is_authenticated
  end

  pipeline :auth_required do
    plug :require_authenticated_user
  end

  # ---------- Routes ----------

  # Public (current-user aware via :browser)
  scope "/", ShardWeb do
    pipe_through [:browser]

    # Controller routes
    get "/", PageController, :home
    get "/music", PageController, :music

    # LiveViews get current_scope via on_mount
    live_session :public, on_mount: [{ShardWeb.UserAuth, :mount_current_scope}] do
      live "/play", PlayLive, :index

      # Characters (public)
      live "/characters", CharacterLive.Index, :index
      live "/characters/new", CharacterLive.New, :new
      live "/characters/:id", CharacterLive.Show, :show

      # Credits page
      live "/credits", CreditsLive, :index
    end

    live_session :requires_auth,
      on_mount: [{ShardWeb.UserAuth, :ensure_authenticated}] do
      live "/settings", PreferencesLive, :index
    end
  end

  # Admin index + admin LiveViews (requires login)
  scope "/admin", ShardWeb do
    pipe_through [:browser, :auth_required]

    # Controller route
    get "/", AdminController, :index

    # LiveViews with current_scope available
    live_session :admin, on_mount: [{ShardWeb.UserAuth, :mount_current_scope}] do
      live "/map", AdminLive.Index, :index
      live "/characters", AdminLive.Characters, :index
      live "/characters/new", AdminLive.Characters, :new
      live "/characters/:id", AdminLive.Characters, :show
      live "/characters/:id/edit", AdminLive.Characters, :edit
    end
  end

  # Admin — Controllers (CRUD)
  scope "/admin", ShardWeb.Admin, as: :admin do
    pipe_through [:browser, :auth_required]
    resources "/rooms", RoomController
    resources "/monsters", MonsterController
    resources "/exits", ExitController
    resources "/music", MusicTrackController
  end

  # Auth pages for visitors (not logged in)
  scope "/", ShardWeb do
    pipe_through [:browser, :redirect_if_authed]

    # LiveViews need current_scope too
    live_session :auth, on_mount: [{ShardWeb.UserAuth, :mount_current_scope}] do
      live "/users/log_in", UserLive.Login, :new
      live "/users/register", UserLive.Registration, :new
      live "/users/confirm/:token", UserLive.Confirmation, :show
    end

    # Controller actions for form POSTs
    post "/users/log_in", UserSessionController, :create
    post "/users/register", UserRegistrationController, :create
  end

  # Logged-in LiveViews (auth enforced via on_mount)
  scope "/", ShardWeb do
    pipe_through [:browser]

    live_session :authed,
      on_mount: [
        {ShardWeb.UserAuth, :ensure_authenticated},
        {ShardWeb.UserAuth, :mount_current_scope}
      ] do
      live "/users/settings", UserLive.Settings, :index
      live "/users/settings/confirm-email/:token", UserLive.Settings, :index
    end

    # Controller endpoint that still uses plugs
    post "/users/update-password", UserSessionController, :update_password
  end

  # Shared (any state)
  scope "/", ShardWeb do
    pipe_through [:browser]
    delete "/users/log_out", UserSessionController, :delete
  end
end

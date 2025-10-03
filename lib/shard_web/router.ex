defmodule ShardWeb.Router do
  use ShardWeb, :router

  import ShardWeb.UserAuth,
    only: [
      fetch_current_scope_for_user: 2,
      require_authenticated_user: 2
    ]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ShardWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  # Separate name to avoid clashing with the imported plug function
  pipeline :auth_browser do
    plug :require_authenticated_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # ----- Public site ---------------------------------------------------------

  scope "/", ShardWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/credits", PageController, :credits
    get "/music", MusicController, :index
    get "/play", PageController, :play

    # Characters (public)
    live "/characters", CharacterLive.Index, :index
    live "/characters/new", CharacterLive.New, :new
    live "/characters/:id", CharacterLive.Show, :show
  end

  # ----- Settings (LiveView) -------------------------------------------------

  scope "/", ShardWeb do
    pipe_through :browser

    # Must be logged in AND within sudo window for /users/settings
    live_session :users_settings,
      on_mount: [
        {ShardWeb.UserAuth, :mount_current_scope},
        {ShardWeb.UserAuth, :require_authenticated},
        {ShardWeb.UserAuth, :require_sudo_mode}
      ] do
      live "/users/settings", UserLive.Settings, :edit
    end

    # Email confirmation from settings: needs login, not sudo
    live_session :users_settings_email,
      on_mount: [
        {ShardWeb.UserAuth, :mount_current_scope},
        {ShardWeb.UserAuth, :require_authenticated}
      ] do
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end
  end

  # ----- Auth (public LV pages, controller POSTs) ----------------------------

  scope "/", ShardWeb do
    pipe_through :browser

    live_session :users_auth_public,
      on_mount: [
        {ShardWeb.UserAuth, :mount_current_scope},
        {ShardWeb.UserAuth, :redirect_if_user_is_authenticated}
      ] do
      # Magic-link page: MUST be above the plain /users/log_in route
      live "/users/log_in/:token", UserLive.Confirmation, :show

      live "/users/register", UserLive.Registration, :new
      live "/users/log_in", UserLive.Login, :new
    end

    post "/users/register", UserRegistrationController, :create
    post "/users/log_in", UserSessionController, :create
    delete "/users/log_out", UserSessionController, :delete
  end

  # ----- Admin area ----------------------------------------------------------

  scope "/admin", ShardWeb.Admin do
    pipe_through [:browser, :auth_browser]
    # plug :require_admin # enable when admin roles exist

    get "/", DashboardController, :index
    live "/map", MapLive, :index

    resources "/rooms", RoomController
    resources "/exits", ExitController
    resources "/music", MusicTrackController
    resources "/monsters", MonsterController

    # If your admin templates reference these LV routes, keep them:
    live "/characters", CharactersLive, :index
    live "/characters/new", CharactersLive, :new
    live "/characters/:id", CharactersLive, :show
    live "/characters/:id/edit", CharactersLive, :edit
  end

  # ----- JSON API ------------------------------------------------------------

  scope "/", ShardWeb do
    pipe_through :api
    get "/map", MapController, :index
  end
end

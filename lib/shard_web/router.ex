defmodule ShardWeb.Router do
  use ShardWeb, :router

  import ShardWeb.UserAuth

  defp ensure_admin(conn, _opts) do
    case conn.assigns[:current_scope] do
      %{user: %{admin: true}} -> conn
      _ ->
        conn
        |> Phoenix.Controller.put_flash(:error, "You must be an admin to access this page.")
        |> Phoenix.Controller.redirect(to: "/")
        |> Plug.Conn.halt()
    end
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
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

  scope "/", ShardWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/play", MudGameLive
  end

  # Admin routes
  scope "/admin", ShardWeb do
    pipe_through [:browser, :require_authenticated_user, :require_admin]

    live "/", AdminLive.Index, :index
    live "/map", AdminLive.Map, :index  # Added this line for the map page
  end

  # Other scopes may use custom stacks.
  # scope "/api", ShardWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:shard, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ShardWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", ShardWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{ShardWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
      live "/characters", CharacterLive.Index, :index
      live "/characters/new", CharacterLive.New, :new
      live "/characters/:id", CharacterLive.Show, :show
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/admin", ShardWeb do
    pipe_through [:browser, :require_authenticated_user, :require_admin]

    live_session :require_admin,
      on_mount: [{ShardWeb.UserAuth, :require_authenticated}] do
      live "/characters", AdminLive.Characters, :index
      live "/characters/new", AdminLive.Characters, :new
      live "/characters/:id", AdminLive.Characters, :show
      live "/characters/:id/edit", AdminLive.Characters, :edit
    end
  end

  scope "/", ShardWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{ShardWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end

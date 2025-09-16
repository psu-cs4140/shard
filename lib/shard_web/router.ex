defmodule ShardWeb.Router do
  use ShardWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ShardWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end
    
  pipeline :admin do
    plug ShardWeb.Plugs.RequireAdmin
  end
plug ShardWeb.Plugs.FetchCurrentUser
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ShardWeb do
    pipe_through :browser
    get "/map", MapController, :index

    get "/", PageController, :home
    # NEW
    live "/play", PlayLive
  end

  if Application.compile_env(:shard, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: ShardWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

  scope "/admin", ShardWeb.Admin do
    pipe_through [:browser, :admin]
    resources "/monsters", MonsterController
  end

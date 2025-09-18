defmodule ShardWeb.Router do
  use ShardWeb, :router

  import Plug.Conn
  import Phoenix.Controller
  import Phoenix.LiveView.Router

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

  # ---- Public / player routes ----
  scope "/", ShardWeb do
    pipe_through :browser
    get "/", PageController, :home
    get "/map", MapController, :index
    live "/play", PlayLive, :index
  end

  # ---- Admin CRUD (Rooms, Exits) ----
  scope "/admin", ShardWeb.Admin do
    pipe_through :browser
    resources "/rooms", RoomController
    resources "/exits", ExitController
  end
end

  scope "/admin", ShardWeb.Admin do
    pipe_through [:browser, :admin]
    resources "/monsters", MonsterController
  end

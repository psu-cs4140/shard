defmodule ShardWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such as controllers,
  components, channels, and so on.

  Use in your app as:

      use ShardWeb, :controller
      use ShardWeb, :html
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  ## Router
  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  ## Channels
  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  ## Controllers
  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json]

      use Gettext, backend: ShardWeb.Gettext
      import Plug.Conn

      unquote(verified_routes())
    end
  end

  ## LiveViews
  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {ShardWeb.Layouts, :root}

      # Bring in ~p, core components (<.button>, <.input>, <.header>, etc.)
      unquote(html_helpers())

      # Make @db_health available in LiveViews/layouts
      on_mount {ShardWeb.Init, :health}
    end
  end

  ## LiveComponents
  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  ## HTML (function components, helpers)
  def html do
    quote do
      use Phoenix.Component

      # Convenience controller functions
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      unquote(html_helpers())
    end
  end

  # Helpers shared by views/components
  defp html_helpers do
    quote do
      use Gettext, backend: ShardWeb.Gettext

      import Phoenix.HTML
      import ShardWeb.CoreComponents

      alias Phoenix.LiveView.JS
      alias ShardWeb.Layouts

      unquote(verified_routes())
    end
  end

  ## Verified Routes
  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: ShardWeb.Endpoint,
        router: ShardWeb.Router,
        statics: ShardWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end


defmodule ShardWeb.Init do
  @moduledoc false
  alias Shard.Health

  # Assign DB health once when a LiveView mounts
  def on_mount(:health, _params, _session, socket) do
    socket = Phoenix.Component.assign_new(socket, :db_health, fn -> Health.db_status() end)
    {:cont, socket}
  end
end

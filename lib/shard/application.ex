defmodule Shard.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        ShardWeb.Telemetry,
        Shard.Repo,
        {DNSCluster, query: Application.get_env(:shard, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Shard.PubSub},
        {Finch, name: Shard.Finch},
        ShardWeb.Endpoint
      ] ++ local_mailbox_child()

    opts = [strategy: :one_for_one, name: Shard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Start Swoosh's in-memory mailbox when adapter is Local **and**
  # the process isn't already running (dev usually starts it for you).
  defp local_mailbox_child do
    case Application.get_env(:shard, Shard.Mailer)[:adapter] do
      Swoosh.Adapters.Local ->
        case :global.whereis_name(Swoosh.Adapters.Local.Storage.Memory) do
          :undefined ->
            [
              %{
                id: Swoosh.Adapters.Local.Storage.Memory,
                start: {Swoosh.Adapters.Local.Storage.Memory, :start, [[]]},
                type: :worker
              }
            ]

          _pid ->
            []
        end

      _ ->
        []
    end
  end

  @impl true
  def config_change(changed, _new, removed) do
    ShardWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

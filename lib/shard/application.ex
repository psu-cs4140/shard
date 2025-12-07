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
        {Registry, keys: :unique, name: Shard.Registry},
        Shard.Combat.Supervisor,
        Shard.Gambling.CoinFlipServer,
        Shard.Weather.WeatherServer,
        Shard.WorldEvents.EventServer,
        ShardWeb.Endpoint
      ] ++ local_mailbox_child()

    opts = [strategy: :one_for_one, name: Shard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Swoosh automatically starts the Local.Storage.Memory process when
  # config :swoosh, local: true is set in dev.exs
  # No need to manually start it here
  defp local_mailbox_child do
    []
  end

  @impl true
  def config_change(changed, _new, removed) do
    ShardWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

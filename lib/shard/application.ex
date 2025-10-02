defmodule Shard.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ShardWeb.Telemetry,
      Shard.Repo,
      {DNSCluster, query: Application.get_env(:shard, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Shard.PubSub},
      Shard.Artifacts.ArtifactServer,
      # Start a worker by calling: Shard.Worker.start_link(arg)
      # {Shard.Worker, arg},
      # Start to serve requests, typically the last entry
      ShardWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Shard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ShardWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

defmodule Shard.Health do
  @moduledoc false
  alias Shard.Repo

  @doc """
  Returns %{reachable?: boolean, pending: integer | :unknown}
  """
  def db_status do
    reachable? =
      case Repo.query("SELECT 1") do
        {:ok, _} -> true
        _ -> false
      end

    pending =
      try do
        mig_path = Path.join(:code.priv_dir(:shard), "repo/migrations")

        Ecto.Migrator.migrations(Repo, mig_path)
        |> Enum.count(fn {status, _version, _name} -> status == :down end)
      rescue
        _ -> :unknown
      end

    %{reachable?: reachable?, pending: pending}
  end
end

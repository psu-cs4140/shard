defmodule ShardWeb.EndpointTest do
  use ExUnit.Case, async: true

  test "endpoint module exists" do
    assert Code.ensure_loaded?(ShardWeb.Endpoint)
  end

  test "endpoint has required functions" do
    assert function_exported?(ShardWeb.Endpoint, :config, 1)
    assert function_exported?(ShardWeb.Endpoint, :config, 2)
  end
end

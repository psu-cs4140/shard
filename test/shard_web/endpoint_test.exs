defmodule ShardWeb.EndpointTest do
  use ExUnit.Case, async: true

  test "endpoint is configured" do
    config = ShardWeb.Endpoint.config(:url)
    assert Keyword.get(config, :host) == "localhost"
  end
end

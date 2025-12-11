defmodule ShardWeb.EndpointTest do
  use ExUnit.Case, async: true

  test "endpoint is configured" do
    assert ShardWeb.Endpoint.config(:url) == [host: "localhost"]
  end
end

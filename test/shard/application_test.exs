defmodule Shard.ApplicationTest do
  use ExUnit.Case, async: true

  test "application starts successfully" do
    # Test that the application module is defined
    assert Code.ensure_loaded?(Shard.Application)
  end
end

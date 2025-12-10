defmodule Shard.MailerTest do
  use ExUnit.Case, async: true

  test "mailer module exists" do
    assert Code.ensure_loaded?(Shard.Mailer)
  end

  test "mailer is configured" do
    # Basic test to ensure mailer module loads
    assert Shard.Mailer.__adapter__() == Swoosh.Adapters.Local
  end
end

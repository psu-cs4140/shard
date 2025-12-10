defmodule ShardWeb.GettextTest do
  use ExUnit.Case, async: true

  test "gettext module exists" do
    assert Code.ensure_loaded?(ShardWeb.Gettext)
  end

  test "gettext has required macros" do
    # Test that basic gettext functions work
    assert ShardWeb.Gettext.__gettext__(:known_locales) == ["en"]
  end
end

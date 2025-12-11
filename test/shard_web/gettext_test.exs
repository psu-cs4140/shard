defmodule ShardWeb.GettextTest do
  use ExUnit.Case, async: true

  test "gettext backend is configured" do
    assert ShardWeb.Gettext.__gettext__(:default_domain) == "default"
    assert ShardWeb.Gettext.__gettext__(:default_locale) == "en"
  end
end

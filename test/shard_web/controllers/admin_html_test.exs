defmodule ShardWeb.AdminHTMLTest do
  use ShardWeb.ConnCase, async: true

  alias ShardWeb.AdminHTML

  describe "AdminHTML module" do
    test "module exists and uses ShardWeb :html" do
      # Test that the module is properly defined
      assert Code.ensure_loaded?(AdminHTML)
      
      # Test that it has the expected functions from using ShardWeb, :html
      assert function_exported?(AdminHTML, :__phoenix_component__, 0)
    end

    test "has embed_templates functionality" do
      # Test that the module can handle template embedding
      # This verifies the embed_templates "admin_html/*" directive works
      assert function_exported?(AdminHTML, :__phoenix_template__, 0)
    end
  end
end

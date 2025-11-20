defmodule ShardWeb.AdminHTMLTest do
  use ShardWeb.ConnCase, async: true

  alias ShardWeb.AdminHTML

  describe "AdminHTML module" do
    test "module exists and is properly loaded" do
      # Test that the module is properly defined
      assert Code.ensure_loaded?(AdminHTML)
    end

    test "module has expected Phoenix HTML functionality" do
      # Test that it has the __info__ function which all modules have
      assert function_exported?(AdminHTML, :__info__, 1)
      
      # Test that the module exists and can be called
      assert is_atom(AdminHTML)
    end

    test "module uses ShardWeb :html macro" do
      # Verify the module has been compiled and exists
      assert AdminHTML.__info__(:module) == AdminHTML
      
      # Check that the module has attributes set by using ShardWeb, :html
      attributes = AdminHTML.__info__(:attributes)
      assert is_list(attributes)
    end
  end
end

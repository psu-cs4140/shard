defmodule ShardWeb.PageHTMLTest do
  use ShardWeb.ConnCase, async: true

  alias ShardWeb.PageHTML

  describe "PageHTML module" do
    test "module exists and can be used" do
      assert Code.ensure_loaded?(PageHTML)
    end

    test "has Phoenix component functionality" do
      # Verify the module has Phoenix component functions
      assert function_exported?(PageHTML, :__components__, 0)
      assert function_exported?(PageHTML, :__phoenix_component_verify__, 1)
    end

    test "has template functions" do
      # Verify that templates are embedded and accessible
      functions = PageHTML.__info__(:functions)

      # Check that the home template function exists (based on the error output)
      assert Enum.any?(functions, fn {name, _arity} ->
               name == :home
             end)
    end

    test "can access embedded templates" do
      # Verify that the module has embedded template functionality
      # The home template should be available as a function
      assert function_exported?(PageHTML, :home, 1)
    end
  end

  describe "template rendering" do
    test "can render home template with assigns" do
      # Test that the home template can be called with assigns
      assigns = %{conn: build_conn()}

      # The home template should return a rendered structure
      result = PageHTML.home(assigns)

      # Should return some kind of rendered content
      assert is_struct(result) or is_binary(result) or is_list(result)
    end
  end
end

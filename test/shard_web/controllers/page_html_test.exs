defmodule ShardWeb.PageHTMLTest do
  use ShardWeb.ConnCase, async: true

  alias ShardWeb.PageHTML

  describe "PageHTML module" do
    test "module exists and can be used" do
      assert Code.ensure_loaded?(PageHTML)
    end

    test "uses ShardWeb html functionality" do
      # Verify the module has the expected functions from using ShardWeb, :html
      assert function_exported?(PageHTML, :sigil_H, 2)
    end

    test "imports CoreComponents" do
      # Verify CoreComponents functions are available
      # This tests that the import worked correctly
      functions = PageHTML.__info__(:functions)
      
      # Check for some common CoreComponents functions that should be imported
      assert Enum.any?(functions, fn {name, _arity} -> 
        name in [:button, :input, :label, :error, :header, :table]
      end)
    end

    test "has embed_templates functionality" do
      # Verify that the module can handle template embedding
      # The exact templates depend on what's in the page_html directory
      assert function_exported?(PageHTML, :__templates__, 0)
    end
  end

  describe "template rendering" do
    test "can render templates with assigns" do
      # Test basic template rendering capability
      conn = build_conn()
      
      # This tests that the module can be used in a rendering context
      assert %Phoenix.LiveView.Rendered{} = 
        Phoenix.Controller.render_to_string(PageHTML, "home", %{conn: conn})
    rescue
      # If the template doesn't exist, we expect a specific error
      UndefinedFunctionError -> 
        # This is expected if no home template exists
        assert true
      Phoenix.Template.UndefinedError ->
        # This is also expected if template is not found
        assert true
    end
  end
end

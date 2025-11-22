defmodule ShardWeb.PageControllerTest do
  use ShardWeb.ConnCase

  describe "GET /" do
    test "renders the home page successfully", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert html_response(conn, 200) =~ "Shard"
    end

    test "returns 200 status code", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert conn.status == 200
    end

    test "contains expected HTML structure", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      assert response =~ "<html"
      assert response =~ "<head"
      assert response =~ "<body"
    end

    test "includes proper content type header", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]
    end

    test "does not require authentication", %{conn: conn} do
      # Test that unauthenticated users can access the home page
      conn = get(conn, ~p"/")
      assert conn.status == 200
      refute redirected_to(conn)
    end
  end

  describe "error handling" do
    test "handles invalid routes gracefully", %{conn: conn} do
      assert_error_sent 404, fn ->
        get(conn, "/nonexistent-route")
      end
    end
  end

  describe "security headers" do
    test "includes security headers in response", %{conn: conn} do
      conn = get(conn, ~p"/")
      
      # Check for common security headers that Phoenix typically includes
      headers = conn.resp_headers |> Enum.into(%{})
      
      # These may vary based on your Phoenix configuration
      assert Map.has_key?(headers, "x-frame-options") or 
             Map.has_key?(headers, "x-content-type-options") or
             Map.has_key?(headers, "x-xss-protection")
    end
  end
end

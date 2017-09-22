defmodule SurvedaOnaConnectorWeb.UserControllerTest do
  use SurvedaOnaConnectorWeb.ConnCase

  alias SurvedaOnaConnector.{User, Repo}

  @create_attrs %{email: "abc@example.com"}
  @update_attrs %{email: "new_email@example.com"}
  @invalid_attrs %{email: nil}

  def fixture(:user) do
    {:ok, user} = %User{}
    |> User.changeset(@create_attrs)
    |> Repo.insert()

    user
  end

  setup %{conn: conn} do
    user = fixture(:user)
    conn = conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")
    {:ok, conn: conn, user: user}
  end

  describe "edit user" do
    test "renders form for editing chosen user", %{conn: conn, user: user} do
      conn = get conn, edit_settings_path(conn, :edit)
      assert html_response(conn, 200) =~ "Edit User"
    end
  end

  describe "update user" do
    test "redirects when data is valid", %{conn: conn, user: user} do
      conn = put conn, update_settings_path(conn, :update), user: @update_attrs
      assert redirected_to(conn) == edit_settings_path(conn, :edit)

      conn = get conn, edit_settings_path(conn, :edit)
      assert html_response(conn, 200) =~ "new_email@example.com"
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put conn, update_settings_path(conn, :update), user: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit User"
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end
end

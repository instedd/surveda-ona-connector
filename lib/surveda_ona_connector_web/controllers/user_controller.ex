defmodule SurvedaOnaConnectorWeb.UserController do
  use SurvedaOnaConnectorWeb, :controller
  alias SurvedaOnaConnector.{Repo, User}

  def edit(conn, _params) do
    user = conn |> Coherehce.current_user
    render(conn, "edit.html", user: user, changeset: User.changeset(user, %{}))
  end

  def update(conn, %{"user" => user_params}) do
    user = conn |> Coherehce.current_user

    case User.update(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: edit_settings_path(conn, :edit))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end
end

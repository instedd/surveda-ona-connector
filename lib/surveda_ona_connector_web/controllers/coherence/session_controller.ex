defmodule SurvedaOnaConnectorWeb.Coherence.SessionController do
  @moduledoc """
  Handle the authentication actions.

  """
  use Coherence.Web, :controller
  alias SurvedaOnaConnector.User
  alias SurvedaOnaConnector.Repo
  use Coherence.Config
  import Ecto.Query

  plug :redirect_logged_in when action in [:new]

  @doc """
  Render the login form.
  """
  def new(conn, params) do
    Guisso.request_auth_code(conn, params["redirect"])
  end

  def oauth_callback(conn, params) do
    {:ok, email, name, redirect} = Guisso.request_auth_token(conn, params)
    user = find_or_create_user(email, name)

    Coherence.Authentication.Session.create_login(conn, user, [id_key: Config.schema_key])
    |> put_flash(:notice, "Signed in successfully.")
    |> redirect(to: redirect || "/")
  end

  defp find_or_create_user(email, _name) do
    case Repo.one(from u in User, where: field(u, :email) == ^email) do
      nil ->
        %User{}
        |> User.changeset(%{email: email})
        |> Repo.insert!
      user -> user
    end
  end

  @doc """
  Logout the user.

  Delete the user's session, track the logout and delete the rememberable cookie.
  """
  def delete(conn, params) do
    delete(conn)
    |> redirect_to(:session_delete, params)
  end

  @doc """
  Delete the user session.
  """
  def delete(conn) do
    apply(Config.auth_module, Config.delete_login, [conn])
  end
end

defmodule SurvedaOnaConnectorWeb.Router do
  use SurvedaOnaConnectorWeb, :router
  use Coherence.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session
  end

  pipeline :protected do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session, protected: true
  end

  scope "/", SurvedaOnaConnectorWeb do
    pipe_through :browser
    get "/session/new", Coherence.SessionController, :new
    get "/session/oauth_callback", Coherence.SessionController, :oauth_callback
  end

  scope "/", SurvedaOnaConnectorWeb do
    pipe_through :protected
    coherence_routes :protected
  end

  scope "/", SurvedaOnaConnectorWeb do
    pipe_through :browser
    # get "/", PageController, :index
    # Add public routes below
  end

  scope "/", SurvedaOnaConnectorWeb do
    pipe_through :protected
    # Add protected routes below

    get "/", ProjectController, :index
    resources "/projects", ProjectController
    get "/projects/:project_id/track_survey/:survey_id/:survey_name", ProjectController, :track_survey, as: :track_survey
    get "/settings", UserController, :edit, as: :edit_settings
    put "/update_settings", UserController, :update, as: :update_settings
  end
end

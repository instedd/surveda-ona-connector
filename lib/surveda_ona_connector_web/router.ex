defmodule SurvedaOnaConnectorWeb.Router do
  use SurvedaOnaConnectorWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SurvedaOnaConnectorWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    resources "/projects", ProjectController
    get "/projects/:project_id/track_survey/:survey_id", ProjectController, :track_survey, as: :track_survey
  end

  # Other scopes may use custom stacks.
  # scope "/api", SurvedaOnaConnectorWeb do
  #   pipe_through :api
  # end
end

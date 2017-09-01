# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :surveda_ona_connector,
  ecto_repos: [SurvedaOnaConnector.Repo]

# Configures the endpoint
config :surveda_ona_connector, SurvedaOnaConnectorWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "S8DuIpUI9jTMqM0Es+kSbA8etrvrTTNtB66tAYR2b0HPm/gnAnwU6baG2To50+8t",
  render_errors: [view: SurvedaOnaConnectorWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: SurvedaOnaConnector.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$dateT$timeZ $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

if File.exists?("#{__DIR__}/local.exs") && Mix.env != :test do
  import_config "local.exs"
end

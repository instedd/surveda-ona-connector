use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :surveda_ona_connector, SurvedaOnaConnectorWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :surveda_ona_connector, SurvedaOnaConnector.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "surveda_ona_connector_test",
  hostname: System.get_env("DATABASE_HOST") || "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

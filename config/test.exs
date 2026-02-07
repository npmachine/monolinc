import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :monolinc, Monolinc.Repo,
  database: Path.expand("../monolinc_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox,
  journal_mode: :wal,
  synchronous: :normal,
  busy_timeout: 2000,
  temp_store: :memory,
  cache_size: -64000,
  foreign_keys: :on

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :monolinc, MonolincWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "a/+pYehVZA9GpeR4Xz+O0CLX5wmRqEpr0gLKPAzV8NxYro3LZXuYp/xs9A7fRGQW",
  server: false

# In test we don't send emails
config :monolinc, Monolinc.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

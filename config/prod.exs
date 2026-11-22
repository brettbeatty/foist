use Mix.Config

config :foist, FoistWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  force_ssl: [rewrite_on: [:x_forwarded_proto], host: nil],
  server: true

config :logger, level: :info

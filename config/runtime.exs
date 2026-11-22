import Config

if config_env() == :prod do
  host = System.get_env("PHX_HOST") || "foist.brettbeatty.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :foist, FoistWeb.Endpoint,
    http: [ip: {0, 0, 0, 0}, port: port],
    url: [scheme: "https", host: host, port: 443],
    secret_key_base: System.fetch_env!("SECRET_KEY_BASE")
end

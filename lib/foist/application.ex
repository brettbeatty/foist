defmodule Foist.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Registers game servers by their join codes
      {Registry, keys: :unique, name: Foist.GameRegistry},
      # Supervises game servers (even though they're temporary)
      {DynamicSupervisor, strategy: :one_for_one, name: Foist.GameSupervisor},
      # Start the Telemetry supervisor
      FoistWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Foist.PubSub},
      # Start the Endpoint (http/https)
      FoistWeb.Endpoint
      # Start a worker by calling: Foist.Worker.start_link(arg)
      # {Foist.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Foist.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    FoistWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

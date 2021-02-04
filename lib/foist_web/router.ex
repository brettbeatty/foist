defmodule FoistWeb.Router do
  use FoistWeb, :router
  alias FoistWeb.PlayerRequired

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {FoistWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", FoistWeb do
    pipe_through :browser

    get "/", WelcomeController, :index
    live "/page", PageLive, :index
    get "/players/new", PlayerController, :new
    post "/players", PlayerController, :create

    scope "/", nil do
      pipe_through PlayerRequired

      get "/games", GameController, :index
      post "/games", GameController, :create
      get "/games/join", GameController, :join_code
      post "/games/join", GameController, :join
      live "/games/:join_code", GameLive, :show
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", FoistWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: FoistWeb.Telemetry
    end
  end
end

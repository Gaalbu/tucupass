defmodule TucupassWeb.Router do
  use TucupassWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TucupassWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TucupassWeb do
    pipe_through :browser

    live "/", HomeLive, :index
    live "/e/:slug", EventLive.Register, :register
    live "/t/:token", TicketLive, :show
    live "/demo", DemoLive, :index
    live "/demo/checkin", CheckinLive, :demo
  end

  scope "/", TucupassWeb do
    pipe_through [:browser, TucupassWeb.Plugs.RequireOrganizer]

    live_session :organizer do
      live "/e/:slug/checkin", CheckinLive, :index
      live "/e/:slug/dashboard", DashboardLive, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", TucupassWeb do
  #   pipe_through :api
  # end

  if Application.compile_env(:tucupass, :dev_routes) do
    scope "/dev" do
      pipe_through :browser
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

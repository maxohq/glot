defmodule Glot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Glot.Worker.start_link(arg)
      # {Glot.Worker, arg}
    ]

    # Add watcher in development
    children =
      if Mix.env() == :dev do
        [{Glot.Watcher, []} | children]
      else
        children
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Glot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule Glot.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = []

    children =
      if Glot.Config.watch?() do
        [{Glot.Watcher, []} | children]
      else
        children
      end

    opts = [strategy: :one_for_one, name: Glot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

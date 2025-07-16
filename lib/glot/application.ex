defmodule Glot.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = []

    children =
      if compile_env() == :dev do
        [{Glot.Watcher, []} | children]
      else
        children
      end

    opts = [strategy: :one_for_one, name: Glot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def compile_env do
    Application.get_env(:glot, :compile_env, Mix.env())
  end
end

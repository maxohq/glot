defmodule Glot.Config do
  @compile_env Application.compile_env(:glot, :compile_env, :dev)

  def compile_env, do: @compile_env

  def watch?, do: @compile_env == :dev
end

defmodule Glot.Lexeme do
  @moduledoc """
  Internal functions for working with glossary lexemes.

  This module is not part of the public API.
  It provides utilities to identify, qualify, and resolve localized expressions
  based on Ecto-style validation metadata.
  """

  require Logger

  @doc """
  Looks up a localized expression in the glossary by its fully qualified key.

  Performs interpolation of placeholders in the form `{{key}}` using values from `bindings`.
  If the key is not found, returns `fallback` or the key itself, and logs a warning.

  ## Examples

      lookup("en.validation.required", glossary, [], nil)
      #=> "can't be blank"

      lookup("en.validation.foo", glossary, [name: "Alice"], nil)
      #=> "Hello, Alice!"

  """
  @spec lookup(String.t(), map(), keyword(), String.t() | nil) :: String.t()
  def lookup(key, glossary, bindings, fallback \\ nil) do
    case Map.get(glossary, key) do
      nil ->
        Logger.warning("[Glot] Missing key: #{key}")
        fallback || key

      expr ->
        Enum.reduce(bindings, expr, fn {k, v}, acc ->
          String.replace(acc, "{{#{k}}}", to_string(v))
        end)
    end
  end

  @doc """
  Builds a lexeme identifier from Ecto validation options.

  The result is used to construct the glossary key. It attempts to match the most
  specific form: `validation.key.kind.type`, then `validation.key.kind`, then `validation.key`.

  Logs a warning and returns `"validation.unknown"` if `:validation` is missing.

  ## Examples

      identify(%{validation: :length, kind: :min, type: :string})
      #=> "validation.length.min.string"

      identify(%{validation: :required})
      #=> "validation.required"
  """
  @spec identify(map()) :: String.t()
  def identify(%{validation: key, kind: kind, type: type}),
    do: "validation.#{key}.#{kind}.#{type}"

  def identify(%{validation: key, kind: kind}),
    do: "validation.#{key}.#{kind}"

  def identify(%{validation: key}),
    do: "validation.#{key}"

  def identify(%{} = opts) do
    "[Glot] Missing key: :validation in Ecto opts #{inspect({opts})}"
    |> Logger.warning()

    "validation.unknown"
  end

  @doc """
  Prepends a locale prefix to a lexeme to produce a fully qualified glossary key.

  ## Examples

      qualify("validation.required", "en")
      #=> "en.validation.required"
  """
  @spec qualify(String.t(), String.t()) :: String.t()
  def qualify(lexeme, locale), do: "#{locale}.#{lexeme}"
end

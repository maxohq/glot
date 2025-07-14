defmodule Glot.Lexicon do
  @moduledoc """
  Compiles JSONL glossaries into a flat map of localized expressions.

  Used internally by `Glot` to build a lexicon of lexeme–expression mappings.
  """

  @doc """
  Compiles a list of JSONL glossary files into a map of keys (`locale.lexeme`) to expressions.

  Automatically marks each file as an external resource for recompilation tracking.
  """
  @spec compile(String.t(), [String.t()], module()) :: map()
  def compile(base_path, sources, module) do
    sources
    |> expand_paths(base_path)
    # |> mark_as_external(module)
    |> load_all_expressions()
  end

  @spec expand_paths([String.t()], String.t()) :: [{String.t(), String.t()}]
  defp expand_paths(sources, base_path) do
    sources
    |> Enum.flat_map(fn source ->
      base_path
      |> Path.join("#{source}.??.jsonl")
      |> Path.wildcard()
      |> Enum.map(&with_locale/1)
    end)
  end

  @spec with_locale(String.t()) :: {String.t(), String.t()}
  defp with_locale(path) do
    filename = Path.basename(path, ".jsonl")
    [_, locale] = String.split(filename, ".", parts: 2)
    {path, locale}
  end

  @spec mark_as_external([{String.t(), String.t()}], module()) :: [{String.t(), String.t()}]
  defp mark_as_external(paths, module) do
    Enum.each(paths, fn {file, _} -> Module.put_attribute(module, :external_resource, file) end)
    paths
  end

  @spec load_all_expressions([{String.t(), String.t()}]) :: map()
  defp load_all_expressions(paths) do
    paths
    |> Enum.flat_map(fn {file, locale} -> read_yaml(file, locale) end)
    |> Enum.into(%{})
  end

  @spec read_yaml(String.t(), String.t()) :: [{String.t(), String.t()}]
  defp read_yaml(file, locale) do
    with true <- File.exists?(file),
         {:ok, rows} <- Glot.Jsonl.read_from_file(file) do
      rows
      |> Enum.map(fn %{"key" => lexeme, "value" => expression} ->
        {"#{locale}.#{lexeme}", expression}
      end)
    else
      _ -> []
    end
  end
end

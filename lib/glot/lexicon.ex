defmodule Glot.Lexicon do
  @moduledoc """
  Compiles JSONL glossaries into a flat map of localized expressions.

  Used internally by `Glot` to build a lexicon of lexeme–expression mappings.
  """

  @doc """
  Compiles a list of JSONL glossary files into a map of keys (`locale.lexeme`) to expressions.

  Returns a tuple of {translations, file_paths} where translations is a map of keys (`locale.lexeme`) to expressions
  and file_paths is a list of file paths that were successfully loaded.
  """
  @spec compile(String.t(), [String.t()]) :: {map(), [String.t()]}
  def compile(base_path, sources) do
    paths = expand_paths(sources, base_path)
    {load_all_expressions(paths), Enum.map(paths, fn {path, _locale} -> path end)}
  end

  @spec expand_paths([String.t()], String.t()) :: [{String.t(), String.t()}]
  defp expand_paths(sources, base_path) do
    sources
    |> Enum.flat_map(fn source ->
      base_path
      |> Path.join("#{source}.*.jsonl")
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

  @spec load_all_expressions([{String.t(), String.t()}]) :: map()
  defp load_all_expressions(paths) do
    paths
    |> Enum.flat_map(fn {file, locale} -> read_jsonl(file, locale) end)
    |> Enum.into(%{})
  end

  @spec read_jsonl(String.t(), String.t()) :: [{String.t(), String.t()}]
  defp read_jsonl(file, locale) do
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

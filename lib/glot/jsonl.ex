defmodule Glot.Jsonl do
  @moduledoc """
  Jsonlines is simpler than JSON, because each line can be parsed separatelly.
  This makes it useful for large files, that still need some structure (CSV falls short here).

  - https://jsonlines.org/on_the_web/
  """

  @doc """
  Writes JSONLines (https://jsonlines.org/examples/) to a file.
  """
  def write_to_file(file_path, list_of_maps) do
    File.rm(file_path)
    {:ok, file} = File.open(file_path, [:utf8, :write])

    for item <- list_of_maps do
      line = format_json_oneline(item)
      IO.write(file, line <> "\n")
    end

    File.close(file)
  end

  def list_to_jsonl(list_of_maps) do
    Enum.map(list_of_maps, &format_json_oneline/1) |> Enum.join("\n")
  end

  # Helper function to format JSON with spaces after commas and colons, but only outside of string values
  defp format_json_oneline(item) do
    json = Jason.encode!(item)
    do_format_json_oneline(json)
  end

  defp do_format_json_oneline(json) do
    do_format_json_oneline(json, false, "", [])
    |> IO.iodata_to_binary()
  end

  defp do_format_json_oneline(<<>>, _in_string, acc, out), do: Enum.reverse([acc | out])

  defp do_format_json_oneline(<<char, rest::binary>>, in_string, acc, out) do
    cond do
      char == ?" ->
        # Toggle in_string unless it's an escaped quote
        prev_char = if acc == "", do: nil, else: String.at(acc, -1)
        new_in_string = if prev_char != "\\", do: !in_string, else: in_string
        do_format_json_oneline(rest, new_in_string, acc <> <<char>>, out)

      in_string ->
        do_format_json_oneline(rest, in_string, acc <> <<char>>, out)

      char == ?: ->
        do_format_json_oneline(rest, in_string, acc <> ": ", out)

      char == ?, ->
        do_format_json_oneline(rest, in_string, acc <> ", ", out)

      true ->
        do_format_json_oneline(rest, in_string, acc <> <<char>>, out)
    end
  end

  @doc """
  Reads a file with JSON-lines, returning {:ok, rows} or {:error, reason}
  """
  def read_from_file(file_path) do
    try do
      rows =
        File.stream!(file_path)
        |> Stream.map(&String.trim/1)
        |> remove_debug_info()
        |> Stream.map(fn line -> Jason.decode!(line) end)
        |> Enum.to_list()

      {:ok, rows}
    rescue
      e in File.Error -> {:error, "File error: #{e.action} #{e.path}: #{e.reason}"}
      e in Jason.DecodeError -> {:error, "JSON decode error: #{inspect(e)}"}
      e -> {:error, "Unexpected error: #{inspect(e)}"}
    end
  end

  def read_from_file!(file_path) do
    File.stream!(file_path)
    |> Stream.map(&String.trim/1)
    |> remove_debug_info()
    |> Stream.map(fn line -> Jason.decode!(line) end)
    |> Enum.to_list()
  end

  ## remove empty lines & comments
  defp remove_debug_info(stream) do
    stream
    |> Stream.reject(&(&1 == ""))
    |> Stream.reject(&(String.slice(&1, 0, 2) == "//"))
  end
end

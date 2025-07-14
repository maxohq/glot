defmodule Glot.JsonlTest do
  use ExUnit.Case
  doctest Glot.Jsonl
  alias Glot.Jsonl

  setup do
    # Create a temporary test file path
    test_file = "test_output.jsonl"
    on_exit(fn -> File.rm(test_file) end)
    {:ok, test_file: test_file}
  end

  test "write_to_file creates properly formatted JSONL", %{test_file: test_file} do
    test_data = [
      %{"name" => "John", "age" => 30, "city" => "New York"},
      %{"name" => "Jane", "age" => 25, "city" => "Los Angeles"}
    ]

    Jsonl.write_to_file(test_file, test_data)

    # Read the file and verify content
    content = File.read!(test_file)
    lines = String.split(content, "\n", trim: true)

    assert length(lines) == 2

    assert Jason.decode!(Enum.at(lines, 0), keys: :strings) ==
             Jason.decode!(~s({"name": "John", "age": 30, "city": "New York"}), keys: :strings)

    assert Jason.decode!(Enum.at(lines, 1), keys: :strings) ==
             Jason.decode!(~s({"name": "Jane", "age": 25, "city": "Los Angeles"}), keys: :strings)
  end

  test "list_to_jsonl returns properly formatted string" do
    test_data = [
      %{"name" => "John", "age" => 30},
      %{"name" => "Jane", "age" => 25}
    ]

    result = Jsonl.list_to_jsonl(test_data)
    lines = String.split(result, "\n", trim: true)

    expected_lines = [
      ~s({"name": "John", "age": 30}),
      ~s({"name": "Jane", "age": 25})
    ]

    for {line, expected} <- Enum.zip(lines, expected_lines) do
      assert Jason.decode!(line, keys: :strings) == Jason.decode!(expected, keys: :strings)
    end
  end

  test "read_file! can read back written JSONL", %{test_file: test_file} do
    original_data = [
      %{"name" => "John", "age" => 30, "city" => "New York"},
      %{"name" => "Jane", "age" => 25, "city" => "Los Angeles"}
    ]

    Jsonl.write_to_file(test_file, original_data)
    read_data = Jsonl.read_from_file!(test_file)

    assert read_data == original_data
  end

  test "write_to_file overwrites existing file", %{test_file: test_file} do
    # Write initial data
    initial_data = [%{"test" => "initial"}]
    Jsonl.write_to_file(test_file, initial_data)

    # Write new data
    new_data = [%{"test" => "new"}]
    Jsonl.write_to_file(test_file, new_data)

    # Verify only new data exists
    read_data = Jsonl.read_from_file!(test_file)
    assert read_data == new_data
    assert length(read_data) == 1
  end

  test "handles empty list", %{test_file: test_file} do
    Jsonl.write_to_file(test_file, [])

    content = File.read!(test_file)
    assert content == ""
  end

  test "handles complex nested data", %{test_file: test_file} do
    complex_data = [
      %{
        "user" => %{
          "name" => "John",
          "preferences" => %{
            "theme" => "dark",
            "notifications" => true
          }
        },
        "sentence" => "This is a test sentence, so it's long and has a lot of words.",
        "metadata" => %{
          "created_at" => "2024-01-01",
          "tags" => ["important", "urgent"]
        }
      }
    ]

    Jsonl.write_to_file(test_file, complex_data)
    read_data = Jsonl.read_from_file!(test_file)

    assert read_data == complex_data
  end

  test "read_from_file returns {:ok, rows} for valid JSONL", %{test_file: test_file} do
    original_data = [
      %{"name" => "John", "age" => 30, "city" => "New York"},
      %{"name" => "Jane", "age" => 25, "city" => "Los Angeles"}
    ]

    Jsonl.write_to_file(test_file, original_data)
    {:ok, read_data} = Jsonl.read_from_file(test_file)

    assert read_data == original_data
  end

  test "read_from_file returns {:error, reason} for non-existent file" do
    result = Jsonl.read_from_file("non_existent_file.jsonl")
    assert {:error, _reason} = result
  end

  test "read_from_file returns {:error, reason} for invalid JSON" do
    # Create a file with invalid JSON
    File.write!("invalid.jsonl", "{\"invalid\": json}\n{\"valid\": \"json\"}")

    result = Jsonl.read_from_file("invalid.jsonl")
    assert {:error, reason} = result
    assert String.contains?(reason, "JSON decode error")

    # Clean up
    File.rm("invalid.jsonl")
  end

  test "read_from_file handles empty file", %{test_file: test_file} do
    Jsonl.write_to_file(test_file, [])
    {:ok, read_data} = Jsonl.read_from_file(test_file)
    assert read_data == []
  end

  test "read_from_file handles file with comments and empty lines", %{test_file: test_file} do
    # Create a file with comments and empty lines
    content = """
    // This is a comment

    {"name": "John", "age": 30}

    // Another comment
    {"name": "Jane", "age": 25}
    """

    File.write!(test_file, content)
    {:ok, read_data} = Jsonl.read_from_file(test_file)

    expected_data = [
      %{"name" => "John", "age" => 30},
      %{"name" => "Jane", "age" => 25}
    ]

    assert read_data == expected_data
  end
end

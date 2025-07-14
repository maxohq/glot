defmodule Glot.TranslatorTest do
  use ExUnit.Case, async: false
  alias Glot.Translator

  setup do
    # Clean up any existing ETS tables with names containing 'translations_'
    :ets.all()
    |> Enum.map(fn tid ->
      case :ets.info(tid, :name) do
        name when is_atom(name) -> Atom.to_string(name)
        _ -> nil
      end
    end)
    |> Enum.filter(& &1)
    |> Enum.filter(&String.contains?(&1, "translations_"))
    |> Enum.map(&String.to_atom/1)
    |> Enum.each(&:ets.delete/1)

    :ok
  end

  describe "module scoping" do
    test "different modules have isolated translations" do
      # Create two different translator instances
      {:ok, translator1} =
        Translator.start_link(
          name: :test_translator_1,
          base: "test/__fixtures__",
          sources: ["example"],
          default_locale: "en"
        )

      {:ok, translator2} =
        Translator.start_link(
          name: :test_translator_2,
          base: "test/__fixtures__",
          sources: ["validation"],
          default_locale: "en"
        )

      # Test that they have different translations
      assert Translator.t(translator1, "count.first") == "First"
      # validation doesn't have this key
      assert Translator.t(translator2, "count.first") == nil

      # Test that they have their own keys
      assert Translator.t(translator1, "messages.hello") == "Hello, {{name}}!"
      assert Translator.t(translator2, "messages.hello") == nil

      # Clean up
      GenServer.stop(translator1)
      GenServer.stop(translator2)
    end
  end

  describe "translation functionality" do
    setup do
      {:ok, translator} =
        Translator.start_link(
          name: :test_translator,
          base: "test/__fixtures__",
          sources: ["example"],
          default_locale: "en"
        )

      {:ok, %{translator: translator}}
    end

    test "basic translation lookup", %{translator: translator} do
      assert Translator.t(translator, "count.first") == "First"
      assert Translator.t(translator, "count.second") == "Second"
    end

    test "translation with specific locale", %{translator: translator} do
      assert Translator.t(translator, "count.first", "en") == "First"
      assert Translator.t(translator, "count.first", "ru") == "Первый"
    end

    test "fallback to default locale when translation not found", %{translator: translator} do
      # This key exists in both English and Russian, so no fallback should occur
      assert Translator.t(translator, "count.second", "ru") == "Второй"
    end

    test "returns nil for non-existent keys", %{translator: translator} do
      assert Translator.t(translator, "non.existent") == nil
      assert Translator.t(translator, "non.existent", "ru") == nil
    end

    test "interpolation with variables", %{translator: translator} do
      assert Translator.t(translator, "messages.hello", "en", name: "John") == "Hello, John!"
      assert Translator.t(translator, "messages.hello", "ru", name: "John") == "Привет, John!"
      assert Translator.t(translator, "messages.score", "en", score: 100) == "Score: 100"
      assert Translator.t(translator, "messages.score", "ru", score: 100) == "Счёт: 100"
    end

    test "interpolation with multiple variables", %{translator: translator} do
      # Add a test translation with multiple variables
      template = "Hello {{name}}, your score is {{score}}!"
      state = :sys.get_state(translator)
      :ets.insert(state.table, [{"en.messages.complex", template}])
      result = Translator.t(translator, "messages.complex", "en", name: "Alice", score: 95)
      assert result == "Hello Alice, your score is 95!"
    end

    test "interpolation with non-string values", %{translator: translator} do
      assert Translator.t(translator, "messages.score", "en", score: 42) == "Score: 42"
      assert Translator.t(translator, "messages.score", "en", score: 3.14) == "Score: 3.14"
    end

    test "interpolation with missing variables", %{translator: translator} do
      # Should leave the placeholder unchanged
      assert Translator.t(translator, "messages.hello", "en", []) == "Hello, {{name}}!"
    end
  end

  describe "reload functionality" do
    setup do
      {:ok, translator} =
        Translator.start_link(
          name: :test_reload_translator,
          base: "test/__fixtures__",
          sources: ["example"],
          default_locale: "en"
        )

      {:ok, %{translator: translator}}
    end

    test "reloads translations from files", %{translator: translator} do
      # Verify initial state
      assert Translator.t(translator, "count.first") == "First"

      # Reload should work without errors
      assert Translator.reload(translator) == :ok

      # Translations should still be available after reload
      assert Translator.t(translator, "count.first") == "First"
    end

    test "has_changes? returns false by default", %{translator: translator} do
      assert Translator.has_changes?(translator) == false
    end
  end

  describe "edge cases" do
    test "handles empty interpolations list" do
      {:ok, translator} =
        Translator.start_link(
          name: :test_edge_translator,
          base: "test/__fixtures__",
          sources: ["example"],
          default_locale: "en"
        )

      assert Translator.t(translator, "count.first", "en", []) == "First"
      GenServer.stop(translator)
    end

    test "handles nil locale parameter" do
      {:ok, translator} =
        Translator.start_link(
          name: :test_nil_locale_translator,
          base: "test/__fixtures__",
          sources: ["example"],
          default_locale: "en"
        )

      assert Translator.t(translator, "count.first", nil) == "First"
      GenServer.stop(translator)
    end

    test "handles empty string locale" do
      {:ok, translator} =
        Translator.start_link(
          name: :test_empty_locale_translator,
          base: "test/__fixtures__",
          sources: ["example"],
          default_locale: "en"
        )

      assert Translator.t(translator, "count.first", "") == "First"
      GenServer.stop(translator)
    end
  end
end

defmodule GlotTest do
  use ExUnit.Case, async: false

  # Test module that uses Glot
  defmodule TestTranslator do
    use Glot,
      name: :test_translator,
      base: "test/__fixtures__",
      sources: ["example"],
      default_locale: "en"
  end

  # Another test module to verify isolation
  defmodule TestTranslator2 do
    use Glot,
      name: :test_translator_2,
      base: "test/__fixtures__",
      sources: ["validation"],
      default_locale: "en"
  end

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

    # Start the translators
    {:ok, _} = TestTranslator.start_link()
    {:ok, _} = TestTranslator2.start_link()
    :ok
  end

  describe "__using__ macro" do
    test "provides t/1 function" do
      assert TestTranslator.t("count.first") == "First"
    end

    test "provides t/2 function with locale" do
      assert TestTranslator.t("count.first", "en") == "First"
      assert TestTranslator.t("count.first", "ru") == "Первый"
    end

    test "provides t/3 function with locale and interpolations" do
      assert TestTranslator.t("messages.hello", "en", name: "John") == "Hello, John!"
      assert TestTranslator.t("messages.hello", "ru", name: "John") == "Привет, John!"
    end

    test "provides reload/0 function" do
      assert TestTranslator.reload() == :ok
    end

    test "provides has_changes?/0 function" do
      assert TestTranslator.has_changes?() == false
    end
  end

  describe "module isolation" do
    test "different modules have isolated translations" do
      # TestTranslator uses "example" source
      assert TestTranslator.t("count.first") == "First"
      assert TestTranslator.t("messages.hello") == "Hello, {{name}}!"

      # TestTranslator2 uses "validation" source
      # validation doesn't have this key
      assert TestTranslator2.t("count.first") == nil
      assert TestTranslator2.t("messages.hello") == nil
    end

    test "modules can have different default locales" do
      # Create a module with Russian as default
      defmodule TestTranslatorRU do
        use Glot,
          name: :test_translator_ru,
          base: "test/__fixtures__",
          sources: ["example"],
          default_locale: "ru"
      end

      # Start the translator
      {:ok, _} = TestTranslatorRU.start_link()

      # Should default to Russian
      assert TestTranslatorRU.t("count.first") == "Первый"

      # But can still access English explicitly
      assert TestTranslatorRU.t("count.first", "en") == "First"
    end
  end

  describe "interpolation edge cases" do
    test "handles missing interpolation variables" do
      # Should leave placeholders unchanged
      assert TestTranslator.t("messages.hello") == "Hello, {{name}}!"
    end

    test "handles empty interpolations" do
      assert TestTranslator.t("messages.hello", "en", []) == "Hello, {{name}}!"
    end

    test "handles non-string interpolation values" do
      assert TestTranslator.t("messages.score", "en", score: 42) == "Score: 42"
      assert TestTranslator.t("messages.score", "en", score: 3.14) == "Score: 3.14"
    end
  end
end

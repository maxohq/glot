defmodule GlotTest do
  use ExUnit.Case, async: false

  # Test module that uses Glot
  defmodule TestTranslator do
    use Glot,
      base: "test/__fixtures__",
      sources: ["example"],
      default_locale: "en"
  end

  # Another test module to verify isolation
  defmodule TestTranslator2 do
    use Glot,
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

    # Start only TestTranslator by default
    start_supervised!(
      {Glot.Translator,
       name: TestTranslator, base: "test/__fixtures__", sources: ["example"], default_locale: "en"}
    )

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
      # Start TestTranslator2 for this specific test with unique name
      unique_name = String.to_atom("test_translator_2_#{:rand.uniform(1_000_000)}")

      {:ok, _pid} =
        Glot.Translator.start_link(
          name: unique_name,
          base: "test/__fixtures__",
          sources: ["validation"],
          default_locale: "en"
        )

      # TestTranslator uses "example" source
      assert TestTranslator.t("count.first") == "First"
      assert TestTranslator.t("messages.hello") == "Hello, {{name}}!"

      # TestTranslator2 uses "validation" source - call directly on the GenServer
      # validation doesn't have this key
      assert Glot.Translator.t(unique_name, "count.first") == nil
      assert Glot.Translator.t(unique_name, "messages.hello") == nil
    end

    test "modules can have different default locales" do
      defmodule TestTranslatorRU do
        use Glot,
          base: "test/__fixtures__",
          sources: ["example"],
          default_locale: "ru"
      end

      unique_name = String.to_atom("test_translator_ru_#{:rand.uniform(1_000_000)}")

      {:ok, _pid} =
        Glot.Translator.start_link(
          name: unique_name,
          base: "test/__fixtures__",
          sources: ["example"],
          default_locale: "ru"
        )

      assert Glot.Translator.t(unique_name, "count.first") == "Первый"
      assert Glot.Translator.t(unique_name, "count.first", "en") == "First"
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

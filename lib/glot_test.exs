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
      defmodule TestTranslatorRU do
        use Glot,
          base: "test/__fixtures__",
          sources: ["example"],
          default_locale: "ru"
      end

      assert TestTranslatorRU.t("count.first") == "Первый"
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

  describe "automatic startup" do
    test "starts GenServer automatically on first use" do
      defmodule AutoStartTest do
        use Glot,
          base: "test/__fixtures__",
          sources: ["example"],
          default_locale: "en"
      end

      # Verify GenServer is not running initially
      assert Process.whereis(AutoStartTest) == nil

      # First call should start the GenServer
      result = AutoStartTest.t("count.first")
      assert result == "First"

      # Verify GenServer is now running
      assert Process.whereis(AutoStartTest) != nil

      # Second call should use the existing GenServer
      result2 = AutoStartTest.t("count.second")
      assert result2 == "Second"
    end
  end

  describe "performance" do
    test "direct ETS access is fast" do
      defmodule PerformanceTest do
        use Glot,
          base: "test/__fixtures__",
          sources: ["example"],
          default_locale: "en"
      end

      # Warm up
      PerformanceTest.t("count.first")

      # Benchmark direct access
      {time, _} =
        :timer.tc(fn ->
          for _ <- 1..1000 do
            PerformanceTest.t("count.first")
          end
        end)

      # Should be very fast (under 10ms for 1000 calls)
      # 10ms in microseconds
      assert time < 10_000
    end
  end

  describe "grep_keys" do
    test "finds keys by substring for a locale" do
      # Test for English locale
      en_results = TestTranslator.grep_keys("en", "count")
      assert length(en_results) == 2
      assert {"en.count.first", "First"} in en_results
      assert {"en.count.second", "Second"} in en_results

      # Test for Russian locale
      ru_results = TestTranslator.grep_keys("ru", "count")
      assert length(ru_results) == 3
      assert {"ru.count.first", "Первый"} in ru_results
      assert {"ru.count.second", "Второй"} in ru_results
      assert {"ru.count.third", "Третий"} in ru_results
    end

    test "finds keys by substring across different key types" do
      # Test for "messages" substring
      results = TestTranslator.grep_keys("en", "messages")
      assert length(results) == 2
      assert {"en.messages.hello", "Hello, {{name}}!"} in results
      assert {"en.messages.score", "Score: {{score}}"} in results
    end

    test "returns empty list for non-matching substring" do
      results = TestTranslator.grep_keys("en", "nonexistent")
      assert results == []
    end

    test "returns empty list for non-matching locale" do
      results = TestTranslator.grep_keys("fr", "count")
      assert results == []
    end

    test "handles case-sensitive substring matching" do
      # Should not find "Count" when searching for "count" (case sensitive)
      results = TestTranslator.grep_keys("en", "Count")
      assert results == []

      # Should find "count" when searching for "count"
      results = TestTranslator.grep_keys("en", "count")
      assert length(results) > 0
    end
  end
end

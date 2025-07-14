defmodule Glot.LexiconTest do
  use ExUnit.Case
  doctest Glot.Lexicon

  test "compile/2 with single source" do
    values = Glot.Lexicon.compile("test/__fixtures__", ["example"])

    assert values == %{
             "en.count.first" => "First",
             "en.count.second" => "Second",
             "en.messages.hello" => "Hello, {{name}}!",
             "en.messages.score" => "Score: {{score}}",
             "ru.count.first" => "Первый",
             "ru.count.second" => "Второй",
             "ru.count.third" => "Третий",
             "ru.messages.hello" => "Привет, {{name}}!",
             "ru.messages.score" => "Счёт: {{score}}"
           }
  end

  test "compile/2 with multiple sources" do
    values = Glot.Lexicon.compile("test/__fixtures__", ["example", "validation"])

    assert values == %{
             "en.count.first" => "First",
             "en.count.second" => "Second",
             "en.messages.hello" => "Hello, {{name}}!",
             "en.messages.score" => "Score: {{score}}",
             "ru.count.first" => "Первый",
             "ru.count.second" => "Второй",
             "ru.count.third" => "Третий",
             "ru.messages.hello" => "Привет, {{name}}!",
             "ru.messages.score" => "Счёт: {{score}}",
             "en.validation.acceptance" => "must be accepted",
             "en.validation.length.is.binary" => "should be {{count}} byte(s)",
             "en.validation.length.is.list" => "should have {{count}} item(s)",
             "en.validation.length.is.map" => "should have {{count}} item(s)",
             "en.validation.length.is.string" => "should be {{count}} character(s)",
             "en.validation.length.min.binary" => "should be at least {{count}} byte(s)",
             "en.validation.length.min.list" => "should have at least {{count}} item(s)",
             "en.validation.length.min.map" => "should have at least {{count}} item(s)",
             "en.validation.length.min.string" => "should be at least {{count}} character(s)",
             "en.validation.required" => "can't be blank",
             "en.validation.term_state" => "Term {{body}} is not NEW but {{state}} instead",
             "ru.validation.acceptance" => "должно быть принято",
             "ru.validation.length.is.binary" => "должно быть {{count}} байт(а)",
             "ru.validation.length.is.list" => "должно быть {{count}} элемент(ов)",
             "ru.validation.length.is.map" => "должно быть {{count}} элемент(ов)",
             "ru.validation.length.is.string" => "должно быть {{count}} символ(ов)",
             "ru.validation.length.min.binary" => "должно быть не менее {{count}} байт(а)",
             "ru.validation.length.min.list" => "должно быть не менее {{count}} элемент(ов)",
             "ru.validation.length.min.map" => "должно быть не менее {{count}} элемент(ов)",
             "ru.validation.length.min.string" => "должно быть не менее {{count}} символ(ов)",
             "ru.validation.required" => "не может быть пустым",
             "ru.validation.term_state" => "Термин {{body}} не NEW, а {{state}}"
           }
  end
end

defmodule Glot.LexiconTest do
  use ExUnit.Case
  doctest Glot.Lexicon

  test "compile/2 with single source" do
    {values, file_paths} = Glot.Lexicon.compile("test/__fixtures__", ["example"])

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
             "be-nl.count.first" => "Eerste",
             "be-nl.count.second" => "Tweede",
             "be-nl.count.third" => "Derde",
             "be-nl.messages.hello" => "Hallo, {{name}}!",
             "be-nl.messages.score" => "Score: {{score}}"
           }

    assert Enum.sort(file_paths) == [
             "test/__fixtures__/example.be-nl.jsonl",
             "test/__fixtures__/example.en.jsonl",
             "test/__fixtures__/example.ru.jsonl"
           ]
  end

  test "compile/2 with multiple sources" do
    {values, file_paths} = Glot.Lexicon.compile("test/__fixtures__", ["example", "validation"])

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
             "be-nl.count.first" => "Eerste",
             "be-nl.count.second" => "Tweede",
             "be-nl.count.third" => "Derde",
             "be-nl.messages.hello" => "Hallo, {{name}}!",
             "be-nl.messages.score" => "Score: {{score}}",
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
             "ru.validation.term_state" => "Термин {{body}} не NEW, а {{state}}",
             "be-nl.validation.acceptance" => "moet geaccepteerd worden",
             "be-nl.validation.length.is.binary" => "moet {{count}} byte(s) zijn",
             "be-nl.validation.length.is.list" => "moet {{count}} item(s) hebben",
             "be-nl.validation.length.is.map" => "moet {{count}} item(s) hebben",
             "be-nl.validation.length.is.string" => "moet {{count}} karakter(s) zijn",
             "be-nl.validation.length.min.binary" => "moet ten minste {{count}} byte(s) zijn",
             "be-nl.validation.length.min.list" => "moet ten minste {{count}} item(s) hebben",
             "be-nl.validation.length.min.map" => "moet ten minste {{count}} item(s) hebben",
             "be-nl.validation.length.min.string" => "moet ten minste {{count}} karakter(s) zijn",
             "be-nl.validation.required" => "kan niet leeg zijn",
             "be-nl.validation.term_state" =>
               "Term {{body}} is niet NEW maar {{state}} in plaats daarvan"
           }

    assert Enum.sort(file_paths) == [
             "test/__fixtures__/example.be-nl.jsonl",
             "test/__fixtures__/example.en.jsonl",
             "test/__fixtures__/example.ru.jsonl",
             "test/__fixtures__/validation.be-nl.jsonl",
             "test/__fixtures__/validation.en.jsonl",
             "test/__fixtures__/validation.ru.jsonl"
           ]
  end
end

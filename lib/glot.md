Minimalistic semantic translation system based on glossaries of lexemes and their expressions.

## Concept

A **lexeme** is a minimal semantic unit (e.g., `"game.won"`), and an **expression**
is its localized realization in a specific language (e.g., `"You won!"`).

A **glossary** is a collection of lexeme–expression mappings for a given language,
typically stored in a JSONL file.

This module injects the functions `t/2` and `t/3` into the caller module for resolving
the expression of a lexeme in a given language using the loaded glossaries.

## Glossaries

Each JSONL file represents a **glossary** — a set of localized expressions.

Glossaries are merged into a single lookup table keyed by `"language.lexeme"`.

Example structure of glossary:

    game.en.jsonl:
    {"key": "game.won", "value": "You won!"}
    {"key": "game.lost", "value": "Game over."}
    {"key": "game.score", "value": "Your score: {{score}}"}
      
    game.ru.jsonl:
    {"key": "game.won", "value": "Вы победили!"}
    {"key": "game.lost", "value": "Игра окончена."}
    {"key": "game.score", "value": "Ваш счёт: {{score}}"}

    user.en.jsonl: 
    {"key": "greeting", "value": "Hello, {{name}}!"}

    user.en.jsonl: 
    {"key": "greeting", "value": "Привет, {{name}}!"}


## Principles

  * Lexemes are **semantic** — they represent **meaning**, not UI position.
    Good: `"game.score"`; Bad: `"label.bottom_right"`
  * Group lexemes in YAML files by shared domain (e.g., `game`, `user`)
  * Prefer flat structures with 2-level keys (domain + key)
  * File name is not part of the lexeme — lookup is clean and abstracted
  * Use `{{key}}` placeholders in expressions for interpolation

## Usage

    use Glossary, ["game", "user"]

Loads:

  - `game.en.jsonl`, `game.ru.jsonl`
  - `user.en.jsonl`, `user.ru.jsonl`

## Expression Lookup

    t("game.won", "en")
    # => "You won!"

    t("game.score", "en", score: 42)
    # => "Your score: 42"

    t("user.greeting", "ru", name: "Алиса")
    # => "Привет, Алиса!"

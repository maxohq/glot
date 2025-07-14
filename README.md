# Glot

> A minimalistic translation system for Elixir applications

[![Hex.pm](https://img.shields.io/hexpm/v/glot)](https://hex.pm/packages/glot)
[![Hex.pm](https://img.shields.io/hexpm/dt/glot)](https://hex.pm/packages/glot)
[![Build Status](https://img.shields.io/github/actions/workflow/status/maxohq/glot/ci.yml)](https://github.com/maxohq/glot/actions)

Glot provides a simple translation system for Elixir applications using JSONL glossaries. It supports interpolation, live reloading in development, and semantic lexeme-based translations.

## Features

- **High Performance**: Direct ETS table access for fast lookups
- **Multi-locale Support**: Easy locale switching with fallback support
- **Live Reloading**: Automatic translation updates during development
- **Interpolation**: Dynamic content with `{{variable}}` placeholders
- **Semantic Keys**: Meaning-based lexemes instead of UI position keys
- **Module Isolation**: Each module gets its own isolated translation table
- **Minimal Dependencies**: Only requires `jason` and `file_system`

## Installation

Add `glot` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:glot, "~> 0.1.0"}
  ]
end
```

## Quick Start

### 1. Create Translation Files

Create JSONL files for each locale and domain:

**`priv/translations/game.en.jsonl`:**
```jsonl
{"key": "game.won", "value": "You won!"}
{"key": "game.lost", "value": "Game over."}
{"key": "game.score", "value": "Your score: {{score}}"}
{"key": "game.greeting", "value": "Hello, {{name}}!"}
```

**`priv/translations/game.ru.jsonl`:**
```jsonl
{"key": "game.won", "value": "Вы победили!"}
{"key": "game.lost", "value": "Игра окончена."}
{"key": "game.score", "value": "Ваш счёт: {{score}}"}
{"key": "game.greeting", "value": "Привет, {{name}}!"}
```

### 2. Use in Your Module

```elixir
defmodule MyApp.Game do
  use Glot,
    base: "priv/translations",
    sources: ["game"],
    default_locale: "en",
    watch: true  # Enable live reloading in development

  def welcome_message(name) do
    t("game.greeting", name: name)
  end

  def score_message(score) do
    t("game.score", score: score)
  end

  def win_message do
    t("game.won")
  end
end
```

### 3. Use Translations

```elixir
# Basic translation
MyApp.Game.win_message()
# => "You won!"

# With interpolation
MyApp.Game.welcome_message("Alice")
# => "Hello, Alice!"

# Different locale
MyApp.Game.t("game.won", "ru")
# => "Вы победили!"

# With interpolation in different locale
MyApp.Game.t("game.score", "ru", score: 100)
# => "Ваш счёт: 100"
```

## API Reference

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `base` | `String` | Required | Base directory for translation files |
| `sources` | `[String]` | Required | List of translation source names |
| `default_locale` | `String` | `"en"` | Default locale for translations |
| `watch` | `Boolean` | `false` | Enable live reloading in development |

### Functions

#### `t(key, locale \\ nil, interpolations \\ [])`

Translates a lexeme key to the specified locale with optional interpolation.

```elixir
# Basic translation
t("game.won")
# => "You won!"

# With locale
t("game.won", "ru")
# => "Вы победили!"

# With interpolation
t("game.score", "en", score: 42)
# => "Your score: 42"

# With locale and interpolation
t("game.greeting", "ru", name: "Алиса")
# => "Привет, Алиса!"
```

#### `reload()`

Reloads translations from files. Useful after manual file changes.

```elixir
MyApp.Game.reload()
# => :ok
```

#### `has_changes?()`

Checks if there are uncommitted changes in the translation table.

```elixir
MyApp.Game.has_changes?()
# => false
```

#### `grep_keys(locale, substring)`

Searches for translation keys containing a substring in a specific locale.

```elixir
MyApp.Game.grep_keys("en", "game")
# => [{"en.game.won", "You won!"}, {"en.game.lost", "Game over."}]
```

#### `loaded_files()`

Lists loaded files for this module.

```elixir
MyApp.Game.loaded_files()
# => [""priv/translations/game.en.jsonl", "priv/translations/game.ru.jsonl"]
```

## Architecture

### Core Components

- **`Glot`**: Main module providing the `use Glot` macro
- **`Glot.Translator`**: GenServer managing translation tables and lookups
- **`Glot.Lexicon`**: Compiles JSONL files into translation maps
- **`Glot.Watcher`**: File system watcher for live reloading
- **`Glot.Jsonl`**: JSONL file parser

### Performance Features

- **ETS Tables**: Fast in-memory lookups using Erlang's ETS
- **Direct Access**: Bypasses GenServer calls for maximum performance
- **Lazy Loading**: GenServer starts automatically on first use
- **Module Isolation**: Each module gets its own ETS table

## Best Practices

### Semantic Lexemes

Use meaningful, semantic keys instead of UI position keys:

```elixir
# Good - semantic meaning
{"key": "game.won", "value": "You won!"}
{"key": "user.greeting", "value": "Hello, {{name}}!"}

# Bad - UI position
{"key": "label.bottom_right", "value": "Submit"}
{"key": "button.header", "value": "Save"}
```

### File Organization

Group translations by domain in separate files:

```
priv/translations/
├── game.en.jsonl      # Game-related translations
├── game.ru.jsonl
├── user.en.jsonl      # User-related translations
├── user.ru.jsonl
├── validation.en.jsonl # Validation messages
└── validation.ru.jsonl
```

### Interpolation

Use `{{variable}}` placeholders for dynamic content:

```jsonl
{"key": "user.welcome", "value": "Welcome back, {{name}}!"}
{"key": "game.score", "value": "Score: {{score}} points"}
{"key": "validation.required", "value": "{{field}} is required"}
```

## Development

### Live Reloading

Enable live reloading in development by setting `watch: true`:

```elixir
use Glot,
  base: "priv/translations",
  sources: ["game"],
  default_locale: "en",
  watch: true  # Automatically reloads when files change
```

### Testing

```elixir
defmodule MyApp.GameTest do
  use ExUnit.Case
  
  defmodule TestGame do
    use Glot,
      base: "test/fixtures",
      sources: ["game"],
      default_locale: "en"
  end

  test "translates basic messages" do
    assert TestGame.t("game.won") == "You won!"
  end

  test "handles interpolation" do
    assert TestGame.t("game.score", score: 100) == "Score: 100"
  end
end
```


### Troubleshooting

If files are not properly picked up, see what is actually being loaded:

```elixir
Glot.Lexicon.compile("priv/seeds/cms", ["home", "about", "pricing"])
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Performance

Glot is designed for efficient translation lookups:

- **Memory efficient**: Uses ETS tables for fast access
- **Direct table access**: Bypasses GenServer calls for hot paths
- **Lazy initialization**: GenServer starts only when needed

## Related Projects

- [Gettext](https://hexdocs.pm/gettext) - Elixir's official internationalization library
- [ExI18n](https://hex.pm/packages/exi18n) - Alternative i18n solution
- [Cldr](https://hex.pm/packages/ex_cldr) - Unicode CLDR data for Elixir
- [glossary](https://hex.pm/packages/glossary/) - Minimalistic semantic translation system for Elixir apps

---

**Made with ❤️ for the Elixir community**


defmodule Glot do
  @moduledoc """
  Use this module to enable translation features for your module.

  ## Options
  - `:base` - The base directory for translation files
  - `:sources` - List of translation sources
  - `:default_locale` - The default locale
  - `:watch` - (optional, default: false) Enable live reloading of translations in development
  """
  defmacro __using__(opts) do
    opts = Keyword.put_new(opts, :name, __CALLER__.module)
    escaped_opts = Macro.escape(opts)

    quote do
      # Store configuration in module attributes for direct access
      @glot_opts unquote(escaped_opts)
      @default_locale @glot_opts[:default_locale]
      @table_name Glot.Translator.to_table_name(@glot_opts[:name])

      def start_link do
        Glot.Translator.start_link(@glot_opts)
      end

      def get_table_name, do: @table_name

      def t(key, locale \\ nil, interpolations \\ []) do
        ensure_started()
        Glot.Translator.t(@table_name, key, locale, @default_locale, interpolations)
      end

      def grep_keys(locale, substring) do
        ensure_started()
        Glot.Translator.grep_keys(@table_name, locale, substring)
      end

      def loaded_files do
        ensure_started()
        Glot.Translator.loaded_files(__MODULE__)
      end

      def reload do
        ensure_started()
        Glot.Translator.reload(__MODULE__)
      end

      def has_changes? do
        ensure_started()
        Glot.Translator.has_changes?(__MODULE__)
      end

      defp ensure_started do
        case Process.whereis(__MODULE__) do
          nil ->
            {:ok, _pid} = start_link()
            :ok

          _pid ->
            :ok
        end
      end
    end
  end
end

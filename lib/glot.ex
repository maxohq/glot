defmodule Glot do
  defmacro __using__(opts) do
    opts = Keyword.put_new(opts, :name, __CALLER__.module)
    escaped_opts = Macro.escape(opts)

    quote do
      def start_link do
        Glot.Translator.start_link(unquote(escaped_opts))
      end

      def t(key, locale \\ nil, interpolations \\ []) do
        Glot.Translator.t(__MODULE__, key, locale, interpolations)
      end

      def reload do
        Glot.Translator.reload(__MODULE__)
      end

      def has_changes? do
        Glot.Translator.has_changes?(__MODULE__)
      end
    end
  end
end

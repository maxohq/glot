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

      defp ensure_started do
        case Process.whereis(__MODULE__) do
          nil ->
            {:ok, _pid} = start_link()
            :ok

          _pid ->
            :ok
        end
      end

      def get_table_name do
        @table_name
      end

      defp interpolate(template, interpolations) do
        Enum.reduce(interpolations, template, fn {key, value}, acc ->
          String.replace(acc, "{{#{key}}}", to_string(value))
        end)
      end

      def t(key, locale \\ nil, interpolations \\ []) do
        ensure_started()

        table_name = get_table_name()
        default_locale = @default_locale
        locale = locale || default_locale

        full_key = "#{locale}.#{key}"

        case :ets.lookup(table_name, full_key) do
          [{^full_key, template}] ->
            interpolate(template, interpolations)

          [] ->
            # Fallback to default locale if not found
            if locale != default_locale do
              default_key = "#{default_locale}.#{key}"

              case :ets.lookup(table_name, default_key) do
                [{^default_key, template}] -> interpolate(template, interpolations)
                [] -> nil
              end
            else
              nil
            end
        end
      end

      def reload do
        ensure_started()
        Glot.Translator.reload(__MODULE__)
      end

      def has_changes? do
        ensure_started()
        Glot.Translator.has_changes?(__MODULE__)
      end

      def grep_keys(locale, substring) do
        ensure_started()
        table_name = get_table_name()

        prefix = "#{locale}."

        :ets.tab2list(table_name)
        |> Enum.filter(fn {key, _val} ->
          String.starts_with?(key, prefix) and String.contains?(key, substring)
        end)
      end

      def child_spec(_opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, []},
          type: :worker,
          restart: :permanent,
          shutdown: 500
        }
      end
    end
  end
end

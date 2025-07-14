defmodule Glot do
  defmacro __using__(opts) do
    opts = Keyword.put_new(opts, :name, __CALLER__.module)
    escaped_opts = Macro.escape(opts)

    quote do
      def start_link do
        Glot.Translator.start_link(unquote(escaped_opts))
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

      def t(key, locale \\ nil, interpolations \\ []) do
        ensure_started()
        Glot.Translator.t(__MODULE__, key, locale, interpolations)
      end

      def reload do
        ensure_started()
        Glot.Translator.reload(__MODULE__)
      end

      def has_changes? do
        ensure_started()
        Glot.Translator.has_changes?(__MODULE__)
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

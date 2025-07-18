defmodule Glot.Translator do
  use GenServer
  require Logger

  @doc """
  Starts the translator with configuration.
  """
  def start_link(opts) do
    opts = if is_list(opts), do: Enum.into(opts, %{}), else: opts
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  def t(ets_table, key, locale, default_locale, interpolations) do
    locale = locale || default_locale
    full_key = "#{locale}.#{key}"

    case :ets.lookup(ets_table, full_key) do
      [{^full_key, template}] ->
        interpolate(template, interpolations)

      [] ->
        # Fallback to default locale if not found
        if locale != default_locale do
          default_key = "#{default_locale}.#{key}"

          case :ets.lookup(ets_table, default_key) do
            [{^default_key, template}] -> interpolate(template, interpolations)
            [] -> nil
          end
        else
          nil
        end
    end
  end

  def grep_keys(ets_table, locale, substring) do
    prefix = "#{locale}."

    :ets.tab2list(ets_table)
    |> Enum.filter(fn {key, _val} ->
      String.starts_with?(key, prefix) and String.contains?(key, substring)
    end)
  end

  @doc """
  Reloads translations from files.
  """
  def reload(pid) do
    GenServer.call(pid, :reload)
  end

  @doc """
  Checks if there are uncommitted changes.
  """
  def has_changes?(pid) do
    GenServer.call(pid, :has_changes?)
  end

  @doc """
  Returns the list of file paths that were used to load translations.
  """
  def loaded_files(pid) do
    GenServer.call(pid, :loaded_files)
  end

  def insert_translation(pid, key, value) do
    GenServer.call(pid, {:insert_translation, key, value})
  end

  def to_table_name(name) do
    String.to_atom("translations_#{name}")
  end

  # GenServer callbacks
  @impl true
  def init(opts) do
    table_name = to_table_name(opts[:name])
    base_path = opts[:base]
    sources = opts[:sources]
    default_locale = opts[:default_locale] || "en"

    # Create ETS table here so the GenServer owns it
    table = :ets.new(table_name, [:set, :named_table, :public])

    # Load initial translations
    {translations, loaded_files} = Glot.Lexicon.compile(base_path, sources)
    :ets.insert(table, Enum.to_list(translations))

    # Register with watcher for live reloading (only if watch: true)
    if Map.get(opts, :watch, false) do
      Glot.Watcher.register_module(opts[:name], base_path)
    end

    state = %{
      table: table,
      table_name: table_name,
      base_path: base_path,
      sources: sources,
      default_locale: default_locale,
      has_changes: false,
      loaded_files: Enum.sort(loaded_files)
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:reload, _from, state) do
    {translations, loaded_files} = Glot.Lexicon.compile(state.base_path, state.sources)
    :ets.delete_all_objects(state.table)
    :ets.insert(state.table, Enum.to_list(translations))
    {:reply, :ok, %{state | has_changes: false, loaded_files: Enum.sort(loaded_files)}}
  end

  @impl true
  def handle_call(:has_changes?, _from, state) do
    {:reply, state.has_changes, state}
  end

  @impl true
  def handle_call(:loaded_files, _from, state) do
    {:reply, state.loaded_files, state}
  end

  @impl true
  def handle_call({:insert_translation, key, value}, _from, state) do
    :ets.insert(state.table, [{key, value}])
    {:reply, :ok, state}
  end

  # Helper functions
  defp interpolate(template, interpolations) do
    Enum.reduce(interpolations, template, fn {key, value}, acc ->
      String.replace(acc, "{{#{key}}}", to_string(value))
    end)
  end
end

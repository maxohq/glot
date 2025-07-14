defmodule Glot.Watcher do
  use GenServer
  require Logger

  @doc """
  Starts the file watcher for live reloading.
  Only starts in development environment.
  """
  def start_link(opts \\ []) do
    if Mix.env() == :dev do
      GenServer.start_link(__MODULE__, opts, name: __MODULE__)
    else
      {:ok, nil}
    end
  end

  @doc """
  Registers a module to be notified when files in the given base path change.
  """
  def register_module(module, base_path) do
    if Process.whereis(__MODULE__) do
      GenServer.call(__MODULE__, {:register_module, module, base_path})
    else
      :ok
    end
  end

  @doc """
  Unregisters a module from file change notifications.
  """
  def unregister_module(module) do
    if Process.whereis(__MODULE__) do
      GenServer.call(__MODULE__, {:unregister_module, module})
    else
      :ok
    end
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    Logger.info("Glot.Watcher started - watching for translation file changes")
    {:ok, %{watchers: %{}, modules: %{}}}
  end

  @impl true
  def handle_call({:register_module, module, base_path}, _from, state) do
    # Normalize the base path
    normalized_path = Path.expand(base_path)

    # Add module to the registry
    modules = Map.update(state.modules, normalized_path, [module], &[module | &1])

    # Start watching the directory if not already watching
    state =
      if Map.has_key?(state.watchers, normalized_path) do
        state
      else
        {:ok, pid} = FileSystem.start_link(dirs: [normalized_path])
        FileSystem.subscribe(pid)
        %{state | watchers: Map.put(state.watchers, normalized_path, pid)}
      end

    {:reply, :ok, %{state | modules: modules}}
  end

  @impl true
  def handle_call({:unregister_module, module}, _from, state) do
    # Remove module from all registries
    modules =
      Map.new(state.modules, fn {path, modules} ->
        {path, Enum.reject(modules, &(&1 == module))}
      end)

    # Stop watching directories that no longer have modules
    {watchers, modules} =
      Enum.reduce(modules, {state.watchers, %{}}, fn {path, modules}, {watchers, acc_modules} ->
        if Enum.empty?(modules) do
          if pid = Map.get(watchers, path) do
            GenServer.stop(pid)
            {Map.delete(watchers, path), acc_modules}
          else
            {watchers, acc_modules}
          end
        else
          {watchers, Map.put(acc_modules, path, modules)}
        end
      end)

    {:reply, :ok, %{state | watchers: watchers, modules: modules}}
  end

  @impl true
  def handle_info({:file_event, _pid, {path, _events}}, state) do
    # Only handle .jsonl files
    if String.ends_with?(path, ".jsonl") do
      # Find the base path for this file
      case find_base_path(path, Map.keys(state.modules)) do
        {:ok, base_path} ->
          # Get modules that depend on this base path
          modules = Map.get(state.modules, base_path, [])

          # Debounce the reload
          Process.send_after(self(), {:reload_modules, modules, path}, 500)

        :error ->
          :ok
      end
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:file_event, _pid, :stop}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:reload_modules, modules, path}, state) do
    Logger.info("Reloading modules due to change in #{path}")

    Enum.each(modules, fn module ->
      try do
        module.reload()
        Logger.info("Successfully reloaded #{module}")
      rescue
        error ->
          Logger.error("Failed to reload #{module}: #{inspect(error)}")
      end
    end)

    {:noreply, state}
  end

  # Helper functions

  defp find_base_path(file_path, base_paths) do
    Enum.find_value(base_paths, :error, fn base_path ->
      if String.starts_with?(file_path, base_path) do
        {:ok, base_path}
      else
        nil
      end
    end)
  end
end

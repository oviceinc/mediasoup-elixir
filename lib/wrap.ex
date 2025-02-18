defmodule Mediasoup.NifWrap do
  @moduledoc false
  # Utilities for wrap Nif

  defmodule EventProxy do
    @moduledoc false
    # Event proxy module for rustler because rustler(nif) can only use local pid.
    use GenServer

    def start(opt) do
      pid = Keyword.fetch!(opt, :pid)
      GenServer.start(__MODULE__, %{pid: pid}, [])
    end

    def init(%{pid: pid} = init_arg) do
      Process.monitor(pid)
      {:ok, init_arg}
    end

    def handle_info(
          {:EXIT, _pid, reason},
          state
        ) do
      {:stop, reason, state}
    end

    def handle_info(
          {:DOWN, _ref, :process, _shutdownpid, reason},
          state
        ) do
      {:stop, reason, state}
    end

    def handle_info(message, %{pid: pid} = state) do
      send(pid, message)
      {:noreply, state}
    end

    def wrap_if_remote_node(pid) do
      try do
        if Process.alive?(pid) do
          pid
        else
          nil
        end
      rescue
        _e in ArgumentError ->
          {:ok, wrapped} = EventProxy.start(pid: pid)
          wrapped
      end
    end
  end

  @spec def_handle_call_nif(any) ::
          {:__block__, [], [{:@, [...], [...]} | {:def, [...], [...]}, ...]}
  defmacro def_handle_call_nif(nif_call_map) do
    quote do
      @nif_map unquote(nif_call_map)
      @nif_keylist Map.keys(@nif_map)

      def handle_call(
            {function, arg},
            _from,
            %{reference: reference} = state
          )
          when function in @nif_keylist do
        try do
          result = apply(Map.fetch!(@nif_map, function), [reference | arg])
          {:reply, result, state}
        rescue
          e -> {:reply, {:raise_error, e}, state}
        end
      end
    end
  end

  @spec def_handle_call_async_nif(any) ::
          {:__block__, [], [{:@, [...], [...]} | {:def, [...], [...]}, ...]}
  defmacro def_handle_call_async_nif(nif_call_map) do
    quote do
      @nif_map unquote(nif_call_map)
      @nif_keylist Map.keys(@nif_map)

      def handle_call(
            {function, arg},
            from,
            %{reference: reference} = state
          )
          when function in @nif_keylist do
        try do
          result = apply(Map.fetch!(@nif_map, function), [reference | arg] ++ [{function, from}])
          {:noreply, state}
        rescue
          e -> {:reply, {:raise_error, e}, state}
        end
      end
    end
  end

  defmacro call(pid, args) do
    quote do
      case GenServer.call(unquote(pid), unquote(args)) do
        {:raise_error, e} -> raise e
        result -> result
      end
    end
  end

  def handle_create_result(create_result, module, supervisor) do
    with {:ok, ref} <- create_result,
         {:ok, pid} <-
           DynamicSupervisor.start_child(
             supervisor,
             {module, [reference: ref]}
           ) do
      {:ok, module.struct_from_pid_and_ref(pid, ref)}
    else
      error -> error
    end
  end
end

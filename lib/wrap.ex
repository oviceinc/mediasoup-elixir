defmodule Mediasoup.NifWrap do
  @moduledoc """
  Wrapper for calling GenServer that hosts NIF resource.
  """

  # Utilities for wrap Nif

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
      try do
        case GenServer.call(unquote(pid), unquote(args)) do
          {:raise_error, e} -> raise e
          {:error} -> :error
          result -> result
        end
      catch
        :exit, e -> {:error, :terminated}
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

  # Common GenServer callbacks for processes hosting a NIF resource.
  # The macros define callback clauses in place, so call them next to the other
  # clauses of the same callback.

  @doc false
  def start_link(module, opt) do
    reference = Keyword.fetch!(opt, :reference)
    GenServer.start_link(module, %{reference: reference}, opt)
  end

  @doc false
  # Notifies :on_close listeners, stops child processes and closes the NIF resource.
  def terminate(reason, %{reference: reference} = state, close_nif) do
    with %{listeners: listeners} <- state do
      Mediasoup.EventListener.send(listeners, :on_close, {:on_close})
    end

    with %{supervisor: supervisor} <- state do
      Mediasoup.Utility.supervisor_clean_stop(supervisor, reason)
    end

    close_nif.(reference)
    :ok
  end

  # Registers an event listener (see `Mediasoup.EventListener`).
  defmacro def_handle_call_event(reply \\ quote(do: {:ok})) do
    quote do
      def handle_call({:event, listener, event_types}, _from, %{listeners: listeners} = state) do
        listeners = Mediasoup.EventListener.add(listeners, listener, event_types)
        {:reply, unquote(reply), %{state | listeners: listeners}}
      end
    end
  end

  defmacro def_handle_call_struct_from_pid() do
    quote do
      def handle_call({:struct_from_pid, _arg}, _from, %{reference: reference} = state) do
        {:reply, struct_from_pid_and_ref(self(), reference), state}
      end
    end
  end

  # Replies to async NIF calls whose result creates a child resource process,
  # e.g. %{produce: Mediasoup.Producer}.
  defmacro def_handle_info_create_result(tag_to_module) do
    quote do
      @create_result_modules unquote(tag_to_module)

      def handle_info(
            {:mediasoup_async_nif_result, {tag, from}, result},
            %{supervisor: supervisor} = state
          )
          when is_map_key(@create_result_modules, tag) do
        module = Map.fetch!(@create_result_modules, tag)
        GenServer.reply(from, Mediasoup.NifWrap.handle_create_result(result, module, supervisor))
        {:noreply, state}
      end
    end
  end

  # Replies to any other async NIF call.
  defmacro def_handle_info_async_reply() do
    quote do
      def handle_info({:mediasoup_async_nif_result, {_, from}, result}, state) do
        GenServer.reply(from, Mediasoup.Nif.unwrap_ok(result))
        {:noreply, state}
      end
    end
  end

  # Removes an event listener that went down.
  defmacro def_handle_info_listener_down() do
    quote do
      def handle_info(
            {:DOWN, _monitor_ref, :process, listener, _reason},
            %{listeners: listeners} = state
          ) do
        {:noreply, %{state | listeners: Mediasoup.EventListener.remove(listeners, listener)}}
      end
    end
  end

  # Stops on the NIF :on_close event and forwards the given NIF events to listeners.
  defmacro def_handle_info_nif_event(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      def handle_info({:nif_internal_event, :on_close}, state), do: {:stop, :normal, state}

      simple_events = Keyword.get(opts, :simple_events, [])
      payload_events = Keyword.get(opts, :payload_events, [])

      if simple_events != [] do
        def handle_info({:nif_internal_event, event}, %{listeners: listeners} = state)
            when event in unquote(simple_events) do
          Mediasoup.EventListener.send(listeners, event, {event})
          {:noreply, state}
        end
      end

      if payload_events != [] do
        def handle_info({:nif_internal_event, event, payload}, %{listeners: listeners} = state)
            when event in unquote(payload_events) do
          Mediasoup.EventListener.send(listeners, event, {event, payload})
          {:noreply, state}
        end
      end
    end
  end
end

defmodule Mediasoup.ProcessWrap do
  @moduledoc """
   Utilities for wrap NifStruct to Process
  """

  defmodule EventProxy do
    @moduledoc """
      Event proxy module for rustler because rustler(nif) can only use local pid.
    """
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
  end

  defmodule Base do
    @moduledoc """
     Wrap NifStruct to Process without children process
    """
    defmacro __using__(_opts) do
      quote do
        use GenServer, restart: :temporary

        def struct(pid) when is_pid(pid) do
          GenServer.call(pid, {:struct, []})
        end

        def start_link(opt) do
          struct = Keyword.fetch!(opt, :struct)
          GenServer.start_link(__MODULE__, struct, opt)
        end

        def init(struct) do
          Process.flag(:trap_exit, true)
          {:ok, %{struct: struct}}
        end

        def handle_call(
              {:struct, []},
              _from,
              %{struct: struct} = state
            ) do
          {:reply, struct, state}
        end

        def handle_call({function, option}, _from, %{struct: struct} = state) do
          {:reply, apply(__MODULE__, function, [struct | option]), state}
        end

        def terminate(_reason, %{struct: struct} = _state) do
          __MODULE__.close(struct)
          :ok
        end

        defoverridable start_link: 1, init: 1, handle_call: 3
      end
    end
  end

  defmodule WithChildren do
    @moduledoc """
     Wrap NifStruct to Process with children process
    """
    defmacro __using__(_opts) do
      quote do
        use GenServer, restart: :temporary

        def struct(pid) when is_pid(pid) do
          GenServer.call(pid, {:struct, []})
        end

        def start_link(opt) do
          struct = Keyword.fetch!(opt, :struct)
          GenServer.start_link(__MODULE__, struct, opt)
        end

        def init(struct) do
          Process.flag(:trap_exit, true)
          {:ok, supervisor} = DynamicSupervisor.start_link(strategy: :one_for_one)

          {:ok, %{struct: struct, supervisor: supervisor}}
        end

        def handle_call(
              {:struct, []},
              _from,
              %{struct: struct} = state
            ) do
          {:reply, struct, state}
        end

        def handle_call(
              {:start_child, module, function, option},
              _from,
              %{struct: struct, supervisor: supervisor} = state
            ) do
          ret =
            with {:ok, child_struct} <-
                   apply(__MODULE__, function, [struct | option]),
                 {:ok, pid} <-
                   DynamicSupervisor.start_child(
                     supervisor,
                     {module, [struct: child_struct]}
                   ) do
              {:ok,
               child_struct
               |> Map.put(:pid, pid)}
            end

          {:reply, ret, state}
        end

        def handle_call({:event, [listener, event_types]}, _from, %{struct: struct} = state) do
          result =
            try do
              # create proxy process because rustler can only use local pid.
              __MODULE__.event(struct, listener, event_types)
            rescue
              e in ArgumentError ->
                {:ok, listener} = EventProxy.start(pid: listener)
                __MODULE__.event(struct, listener, event_types)
            end

          {:reply, result, state}
        end

        def handle_call({function, option}, _from, %{struct: struct} = state) do
          {:reply, apply(__MODULE__, function, [struct | option]), state}
        end

        def terminate(reason, %{struct: struct, supervisor: supervisor} = _state) do
          __MODULE__.close(struct)
          DynamicSupervisor.stop(supervisor, reason)
          :ok
        end

        defoverridable start_link: 1, init: 1, handle_call: 3
      end
    end
  end
end

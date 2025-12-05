defmodule Mediasoup.LoggerProxy do
  @moduledoc """
  Proxy rust layer logs to elixir logger

  Usage:
  ```
    defmodule MyApp.App do
      use Application

      def start(_type, _args) do
        children = [
          { Mediasoup.LoggerProxy, max_level: :info }
          # ..other children..
        ]
        Supervisor.start_link(children, strategy: :one_for_one, name: MyApp.Supervisor)
      end
    end
  ```

  """

  require Logger
  use GenServer

  defmodule Record do
    @moduledoc """
    Struct of log record
    """

    defstruct [
      :level,
      :target,
      :module_path,
      :file,
      :line,
      :body
    ]

    @type t :: %__MODULE__{
            level: :error | :warn | :info | :debug,
            target: String.t(),
            module_path: String.t() | nil,
            file: String.t() | nil,
            line: integer() | nil,
            body: String.t()
          }
  end

  @type filter_fun :: (Record.t() -> :log | {:log, Record.t()} | :stop | :ignore)
  @type config ::
          {:max_level, :off | :error | :warn | :info | :debug}
          | {:filters, [filter_fun()]}

  @spec start_link([config]) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(config \\ []) do
    max_level = Keyword.get(config, :max_level, :error)
    filters = Keyword.get(config, :filters, [])

    GenServer.start_link(Mediasoup.LoggerProxy, %{max_level: max_level, filters: filters},
      name: __MODULE__
    )
  end

  def init(init_arg) do
    Mediasoup.Nif.set_logger_proxy_process(self(), init_arg[:max_level])
    {:ok, init_arg}
  end

  def handle_info(%Mediasoup.LoggerProxy.Record{} = msg, %{filters: filters} = state) do
    with {:log, msg} <-
           Enum.reduce_while(filters, {:log, msg}, fn filter, acc ->
             case filter.(msg) do
               :log -> {:halt, acc}
               {:log, changed} -> {:halt, {:log, changed}}
               :stop -> {:halt, :stop}
               _ -> {:cont, acc}
             end
           end) do
      Logger.log(to_logger_level(msg.level), msg.body, %{
        line: msg.line,
        file: msg.file,
        mfa: msg.target,
        module_path: msg.module_path
      })
    end

    {:noreply, state}
  end

  defp to_logger_level(:error), do: :error
  defp to_logger_level(:warn), do: :warning
  defp to_logger_level(:info), do: :info
  defp to_logger_level(:debug), do: :debug
  defp to_logger_level(_), do: :error

  def child_spec(opts) do
    %{
      id: Mediasoup.LoggerProxy,
      start: {__MODULE__, :start_link, [opts]},
      shutdown: 5_000,
      restart: :permanent,
      type: :worker
    }
  end
end

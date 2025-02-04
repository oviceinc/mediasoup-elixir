defmodule Mediasoup.LoggerProxy do
  @moduledoc """
  Proxy rust layer logs to elixir logger.
  This module serves as a bridge between Rust's logging system and Elixir's Logger.

  ## Filters
  Filters can be used to control log output behavior. Each filter is a function that takes
  a Record struct and returns one of these values:
  - `:log` - Allow the message to be logged
  - `:stop` - Stop the message from being logged
  - `:ignore` - Skip this filter and continue to the next one

  Example:
  ```
  filters: [
    fn record ->
      if String.contains?(record.body, "sensitive") do
        :stop
      else
        :ignore
      end
    end
  ]
  ```

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
    Represents a log record structure containing all necessary logging information.
    Used to pass logging data between Rust and Elixir layers.
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
            # The logging level
            level: :error | :warn | :info | :debug,
            # The target module/component
            target: String.t(),
            # Full module path
            module_path: String.t() | nil,
            # Source file where log originated
            file: String.t() | nil,
            # Line number in source file
            line: integer() | nil,
            # The actual log message
            body: String.t()
          }
  end

  # Maximum logging level to process
  @type config ::
          {:max_level, :off | :error | :warn | :info | :debug}
          # Optional filter functions
          | {:filters, [(Record.t() -> :ignore | :log | :stop)] | nil}

  @doc """
  Starts the logger proxy process.

  ## Parameters
    * config - Keyword list of configuration options:
      * :max_level - Maximum log level to process (:off | :error | :warn | :info | :debug)
      * :filters - List of filter functions that can modify logging behavior. Each filter
        receives a Record struct and returns :log, :stop, or :ignore. If any filter
        returns :stop, the message will not be logged. If a filter returns :log,
        the message will be logged immediately. :ignore means continue to next filter.

  ## Examples
      iex> filters = [
      ...>   fn %{body: body} -> if String.contains?(body, "error"), do: :log, else: :ignore end,
      ...>   fn %{level: level} -> if level == :debug, do: :stop, else: :ignore end
      ...> ]
      iex> Mediasoup.LoggerProxy.start_link(max_level: :info, filters: filters)
  """
  @spec start_link([config]) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(config \\ []) do
    max_level = Keyword.get(config, :max_level, :error)
    filters = Keyword.get(config, :filters, [])

    GenServer.start_link(Mediasoup.LoggerProxy, %{max_level: max_level, filters: filters},
      name: __MODULE__
    )
  end

  @doc """
  Initializes the logger proxy with the given configuration and sets up the Rust-side logger.
  """
  def init(init_arg) do
    Mediasoup.Nif.set_logger_proxy_process(self(), init_arg[:max_level])
    {:ok, init_arg}
  end

  @doc """
  Handles incoming log messages from the Rust layer.
  Applies filters and forwards messages to the Elixir Logger if appropriate.
  """
  def handle_info(%Mediasoup.LoggerProxy.Record{} = msg, %{filters: filters} = state) do
    log =
      Enum.reduce_while(filters, :log, fn filter, _ ->
        case filter.(msg) do
          :log -> {:halt, :log}
          :stop -> {:halt, :stop}
          _ -> {:cont, :log}
        end
      end)

    if log === :log do
      Logger.log(msg.level, msg.body, %{
        line: msg.line,
        file: msg.file,
        mfa: msg.target,
        module_path: msg.module_path
      })
    end

    {:noreply, state}
  end

  @doc """
  Provides supervisor child specification for the logger proxy.
  """
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

defmodule Mediasoup do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/
  """
  alias Mediasoup.{Worker, Nif}

  @doc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#mediasoup-createWorker
  """
  @spec create_worker() :: {:ok, Worker.t()} | {:error, String.t()}
  def create_worker() do
    Nif.create_worker()
  end

  @spec create_worker(Worker.Settings.t() | Worker.create_option()) ::
          {:ok, Worker.t()} | {:error, String.t()}
  def create_worker(%Worker.Settings{} = settings) do
    Nif.create_worker(settings)
  end

  def create_worker(option) do
    Nif.create_worker(Worker.Settings.from_map(option))
  end

  @type num_sctp_streams :: %{OS: integer(), MIS: integer()}
  @type transport_listen_ip :: %{:ip => String.t(), optional(:announcedIp) => String.t() | nil}
end

defmodule Mediasoup.Worker do
  alias Mediasoup.{Worker, Router, Nif}

  @enforce_keys [:id, :reference]
  defstruct [:id, :reference]
  @type t(id, reference) :: %Worker{id: id, reference: reference}
  @type t :: %Worker{id: String.t(), reference: reference}

  @type log_level :: :debug | :warn | :error | :none
  @type log_tag ::
          :info
          | :ice
          | :dtls
          | :rtp
          | :srtp
          | :rtcp
          | :rtx
          | :bwe
          | :score
          | :simulcast
          | :svc
          | :sctp
          | :message
  @type create_option :: %{
          optional(:logLevel) => log_level,
          optional(:logTags) => [log_tag],
          optional(:rtcMinPort) => integer,
          optional(:rtcMaxPort) => integer,
          optional(:dtlsCertificateFile) => String.t(),
          optional(:dtlsPrivateKeyFile) => String.t()
        }
  @type update_option :: %{
          optional(:logLevel) => log_level,
          optional(:logTags) => [log_tag]
        }

  @spec close(t) :: {:ok} | {:error}
  def close(worker) do
    Nif.worker_close(worker.reference)
  end

  @spec create_router(t, Router.create_option()) :: {:ok, Router.t()} | {:error}
  def create_router(worker, option) do
    Nif.worker_create_router(worker.reference, option)
  end

  @spec update_settings(t, update_option) :: {:ok} | {:error}
  def update_settings(worker, pid) do
    Nif.worker_update_settings(worker.reference, pid)
  end

  @spec closed?(t) :: boolean
  def closed?(worker) do
    Nif.worker_closed(worker.reference)
  end

  @spec dump(t) :: map
  def dump(worker) do
    Nif.worker_dump(worker.reference)
  end

  @spec event(t, pid) :: {:ok} | {:error}
  def event(worker, pid) do
    Nif.worker_event(worker.reference, pid)
  end
end

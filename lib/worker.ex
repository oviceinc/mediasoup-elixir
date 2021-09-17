defmodule Mediasoup.Worker do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#Worker
  """
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
  def close(%Worker{reference: reference}) do
    Nif.worker_close(reference)
  end

  @spec create_router(t, Router.create_option()) :: {:ok, Router.t()} | {:error}
  def create_router(%Worker{reference: reference}, option) do
    Nif.worker_create_router(reference, option)
  end

  @spec update_settings(t, update_option) :: {:ok} | {:error}
  def update_settings(%Worker{reference: reference}, pid) do
    Nif.worker_update_settings(reference, pid)
  end

  @spec closed?(t) :: boolean
  def closed?(%Worker{reference: reference}) do
    Nif.worker_closed(reference)
  end

  @spec dump(t) :: map
  def dump(%Worker{reference: reference}) do
    Nif.worker_dump(reference)
  end

  @spec event(t, pid) :: {:ok} | {:error}
  def event(%Worker{reference: reference}, pid) do
    Nif.worker_event(reference, pid)
  end

  defmodule Settings do
    @moduledoc """
    https://mediasoup.org/documentation/v3/mediasoup/api/#WorkerSettings
    """
    defstruct log_level: nil,
              log_tags: nil,
              rtc_min_port: nil,
              rtc_max_port: nil,
              dtls_certificate_file: nil,
              dtls_private_key_file: nil

    @type t :: %Settings{
            log_level: Worker.log_level() | nil,
            log_tags: [Worker.log_tag()] | nil,
            rtc_min_port: integer | nil,
            rtc_max_port: integer | nil,
            dtls_certificate_file: String.t() | nil,
            dtls_private_key_file: String.t() | nil
          }
  end
end

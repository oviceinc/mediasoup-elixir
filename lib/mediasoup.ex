defmodule Mediasoup do
  @moduledoc """
  Documentation for `Mediasoup`.
  """
  alias Mediasoup.{Worker, Nif}

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
    Nif.create_worker(%Worker.Settings{
      log_level: option["logLevel"] || option[:logLevel],
      log_tags: option["logTags"] || option[:logTags],
      rtc_min_port: option["rtcMinPort"] || option[:rtcMinPort],
      rtc_max_port: option["rtcMaxPort"] || option[:rtcMaxPort],
      dtls_certificate_file: option["dtlsCertificateFile"] || option[:dtlsCertificateFile],
      dtls_private_key_file: option["dtlsPrivateKeyFile"] || option[:dtlsPrivateKeyFile]
    })
  end
end

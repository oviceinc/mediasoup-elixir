defmodule IntegrateTest.WorkerTest do
  @moduledoc """
  test for Worker with dializer check
  """
  import ExUnit.Assertions
  alias Mediasoup.Worker

  def create_worker_with_default_settings() do
    {:ok, worker} = Mediasoup.create_worker()

    assert is_binary(Worker.id(worker))
    assert false == Mediasoup.Worker.closed?(worker)
    Mediasoup.Worker.close(worker)
  end

  def create_worker_with_struct() do
    {:ok, worker} =
      Mediasoup.create_worker(%Mediasoup.Worker.Settings{
        rtc_min_port: 0,
        rtc_max_port: 9999,
        log_level: :debug,
        log_tags: [:info],
        dtls_certificate_file: "test/data/dtls-cert.pem",
        dtls_private_key_file: "test/data/dtls-key.pem"
      })

    assert true == is_binary(worker.id)
    Mediasoup.Worker.close(worker)
  end

  def worker_with_custom_settings() do
    {:ok, worker} =
      Mediasoup.create_worker(%{
        rtcMinPort: 0,
        rtcMaxPort: 9999,
        logLevel: :debug,
        logTags: [:info],
        dtlsCertificateFile: "test/data/dtls-cert.pem",
        dtlsPrivateKeyFile: "test/data/dtls-key.pem"
      })

    assert true == is_binary(worker.id)
    Mediasoup.Worker.close(worker)
  end

  def worker_with_wrong_settings_cert() do
    assert match?(
             {:error, _},
             Mediasoup.create_worker(%{
               logLevel: :none,
               dtlsCertificateFile: "/notfound/cert.pem",
               dtlsPrivateKeyFile: "/notfound/priv.pem"
             })
           )
  end

  def worker_with_wrong_settings_port() do
    assert match?(
             {:error, _},
             Mediasoup.create_worker(%{
               rtcMinPort: 1000,
               rtcMaxPort: 999
             })
           )
  end

  def update_settings_succeeds() do
    {:ok, worker} = Mediasoup.create_worker()

    assert match?(
             {:ok},
             Worker.update_settings(worker, %{
               logLevel: :none,
               logTags: [:info, :sctp, :message]
             })
           )

    Mediasoup.Worker.close(worker)
  end

  def dump_succeeds() do
    {:ok, worker} =
      Mediasoup.create_worker(%{
        logLevel: :debug
      })

    assert match?(%{"routerIds" => []}, Worker.dump(worker))
    Mediasoup.Worker.close(worker)
  end

  def close_event() do
    {:ok, worker} = Mediasoup.create_worker()

    Worker.event(worker, self())
    Worker.close(worker)

    assert_receive {:on_close}
  end
end

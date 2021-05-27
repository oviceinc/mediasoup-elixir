defmodule IntegrateTest.WorkerTest do
  import ExUnit.Assertions
  alias Mediasoup.Worker

  def create_worker_with_default_settings() do
    {:ok, worker} = Mediasoup.create_worker()

    assert false == Mediasoup.Worker.closed?(worker)
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
  end

  def worker_with_wrong_settings_cert() do
    assert match?(
             {:error, _},
             Mediasoup.create_worker(%{
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
  end

  def dump_succeeds() do
    {:ok, worker} =
      Mediasoup.create_worker(%{
        logLevel: :debug
      })

    assert match?(%{"routerIds" => []}, Worker.dump(worker))
  end

  def close_event() do
    {:ok, worker} = Mediasoup.create_worker()

    Worker.event(worker, self())
    Worker.close(worker)

    receive do
      {:on_close} -> {}
    end
  end
end

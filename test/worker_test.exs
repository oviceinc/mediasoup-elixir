defmodule WorkerTest do
  use ExUnit.Case
  alias Mediasoup.Worker

  test "create_worker with default settings" do
    assert {:ok, worker} = Mediasoup.create_worker()

    assert false === Mediasoup.Worker.closed?(worker)
  end

  test "worker with custom settings" do
    assert {:ok, worker} =
             Mediasoup.create_worker(%{
               rtcMinPort: 0,
               rtcMaxPort: 9999,
               logLevel: :debug,
               logTags: [:info],
               dtlsCertificateFile: "test/data/dtls-cert.pem",
               dtlsPrivateKeyFile: "test/data/dtls-key.pem"
             })

    assert is_binary(worker.id)
  end

  test "worker with wrong settings cert" do
    assert {:error, _} =
             Mediasoup.create_worker(%{
               dtlsCertificateFile: "/notfound/cert.pem",
               dtlsPrivateKeyFile: "/notfound/priv.pem"
             })
  end

  test "worker with wrong settings port" do
    assert {:error, _} =
             Mediasoup.create_worker(%{
               rtcMinPort: 1000,
               rtcMaxPort: 999
             })
  end

  test "update settings succeeds" do
    {:ok, worker} = Mediasoup.create_worker()

    assert {:ok} =
             Worker.update_settings(worker, %{
               logLevel: :none,
               logTags: [:info, :sctp, :message]
             })
  end

  test "dump succeeds" do
    {:ok, worker} =
      Mediasoup.create_worker(%{
        logLevel: :debug
      })

    assert %{"routerIds" => []} = Worker.dump(worker)
  end

  test "close event" do
    {:ok, worker} = Mediasoup.create_worker()

    Worker.event(worker, self())
    Worker.close(worker)

    receive do
      {:on_close} -> {}
    end
  end
end

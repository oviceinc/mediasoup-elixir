defmodule RouterTest do
  use ExUnit.Case

  setup do
    settings = %{
      rtcMinPort: 10000,
      rtcMaxPort: 10010,
      logLevel: :error
    }

    {:ok, worker} = Mediasoup.Worker.start_link(settings: settings)

    %{worker: worker}
  end

  import Mediasoup.TestUtil
  setup_all :worker_leak_setup_all
  setup :verify_worker_leak_on_exit!

  test "create_router_succeeds", %{worker: worker} do
    IntegrateTest.RouterTest.create_router_succeeds(worker)
  end

  test "router_dump", %{worker: worker} do
    IntegrateTest.RouterTest.router_dump(worker)
  end

  test "close_event", %{worker: worker} do
    IntegrateTest.RouterTest.close_event(worker)
  end

  test "close_worker", %{worker: worker} do
    IntegrateTest.RouterTest.close_worker(worker)
  end

  test "do not crash when badarg", %{worker: worker} do
    {:ok, router} =
      Mediasoup.Worker.create_router(worker, %{
        mediaCodecs: {
          %{
            kind: "audio",
            mimeType: "audio/opus",
            clockRate: 48000,
            channels: 2,
            parameters: %{},
            rtcpFeedback: []
          }
        }
      })

    assert_raise ArgumentError, fn ->
      Mediasoup.Router.can_consume?(router, {:badarg}, %{})
    end
  end
end

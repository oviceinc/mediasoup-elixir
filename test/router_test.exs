defmodule RouterTest do
  use ExUnit.Case

  setup do
    settings = %{
      rtcMinPort: 10000,
      rtcMaxPort: 10010,
      logLevel: :debug
    }

    {:ok, struct_worker} = Mediasoup.create_worker(settings)

    {:ok, process_worker} = Mediasoup.Worker.start_link(settings: settings)

    %{struct_worker: struct_worker, process_worker: process_worker}
  end

  test "create_router_succeeds", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.RouterTest.create_router_succeeds(struct_worker)
    IntegrateTest.RouterTest.create_router_succeeds(process_worker)
  end

  test "router_dump", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.RouterTest.router_dump(struct_worker)
    IntegrateTest.RouterTest.router_dump(process_worker)
  end

  test "close_event", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.RouterTest.close_event(struct_worker)
    IntegrateTest.RouterTest.close_event(process_worker)
  end

  test "close_worker", %{struct_worker: _struct_worker, process_worker: process_worker} do
    # struct version not supported
    #   IntegrateTest.RouterTest.close_worker(struct_worker)
    IntegrateTest.RouterTest.close_worker(process_worker)
  end
end

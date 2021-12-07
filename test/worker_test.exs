defmodule WorkerTest do
  use ExUnit.Case

  test "create_worker_with_default_settings" do
    IntegrateTest.WorkerTest.create_worker_with_default_settings()
  end

  test "worker_with_custom_settings" do
    IntegrateTest.WorkerTest.worker_with_custom_settings()
  end

  test "create_worker_with_struct" do
    IntegrateTest.WorkerTest.create_worker_with_struct()
  end

  test "worker with wrong settings cert" do
    # TODO: workaround for deadlock
    # IntegrateTest.WorkerTest.worker_with_wrong_settings_cert()
  end

  test "worker_with_wrong_settings_port" do
    IntegrateTest.WorkerTest.worker_with_wrong_settings_port()
  end

  test "update_settings_succeeds" do
    IntegrateTest.WorkerTest.update_settings_succeeds()
  end

  test "dump_succeeds" do
    IntegrateTest.WorkerTest.dump_succeeds()
  end

  test "close_event" do
    IntegrateTest.WorkerTest.close_event()
  end

  test "close_router" do
    IntegrateTest.WorkerTest.close_router()
  end

  test "create_many_worker" do
    IntegrateTest.WorkerTest.create_many_worker()
  end
end

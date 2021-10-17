defmodule WorkerTest do
  use ExUnit.Case

  test "create_worker_with_default_settings" do
    IntegrateTest.WorkerTest.create_worker_with_default_settings()
    IntegrateTest.WorkerProcessTest.create_worker_with_default_settings()
  end

  test "worker_with_custom_settings" do
    IntegrateTest.WorkerTest.worker_with_custom_settings()
    IntegrateTest.WorkerProcessTest.worker_with_custom_settings()
  end

  test "create_worker_with_struct" do
    IntegrateTest.WorkerTest.create_worker_with_struct()
    IntegrateTest.WorkerProcessTest.create_worker_with_struct()
  end

  test "worker with wrong settings cert" do
    IntegrateTest.WorkerTest.worker_with_wrong_settings_cert()
    IntegrateTest.WorkerProcessTest.worker_with_wrong_settings_cert()
  end

  test "worker_with_wrong_settings_port" do
    IntegrateTest.WorkerTest.worker_with_wrong_settings_port()
    IntegrateTest.WorkerProcessTest.worker_with_wrong_settings_port()
  end

  test "update_settings_succeeds" do
    IntegrateTest.WorkerTest.update_settings_succeeds()
    IntegrateTest.WorkerProcessTest.update_settings_succeeds()
  end

  test "dump_succeeds" do
    IntegrateTest.WorkerTest.dump_succeeds()
    IntegrateTest.WorkerProcessTest.dump_succeeds()
  end

  test "close_event" do
    IntegrateTest.WorkerTest.close_event()
    IntegrateTest.WorkerProcessTest.close_event()
  end
end

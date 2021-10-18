defmodule IntegrateTest.WorkerProcessTest do
  @moduledoc """
  test for Worker with dializer check
  """
  import ExUnit.Assertions
  alias Mediasoup.Worker

  def create_worker_with_default_settings() do
    {:ok, worker} = Worker.start_link()

    assert is_binary(Worker.id(worker))
    assert false == Mediasoup.Worker.closed?(worker)
    Mediasoup.Worker.close(worker)
  end

  def create_worker_with_struct() do
    {:ok, worker} =
      Worker.start_link(
        settings: %Mediasoup.Worker.Settings{
          rtc_min_port: 0,
          rtc_max_port: 9999,
          log_level: :debug,
          log_tags: [:info],
          dtls_certificate_file: "test/data/dtls-cert.pem",
          dtls_private_key_file: "test/data/dtls-key.pem"
        }
      )

    assert true == is_binary(Worker.id(worker))
    Worker.close(worker)
  end

  def worker_with_custom_settings() do
    {:ok, worker} =
      Worker.start_link(
        settings: %Worker.Settings{
          rtc_min_port: 0,
          rtc_max_port: 9999,
          log_level: :debug,
          log_tags: [:info],
          dtls_certificate_file: "test/data/dtls-cert.pem",
          dtls_private_key_file: "test/data/dtls-key.pem"
        }
      )

    assert true == is_binary(worker |> Worker.id())
    Mediasoup.Worker.close(worker)
  end

  def worker_with_wrong_settings_cert() do
    assert match?(
             {:error, _},
             Worker.start_link(
               settings: %Worker.Settings{
                 log_level: :none,
                 dtls_certificate_file: "/notfound/cert.pem",
                 dtls_private_key_file: "/notfound/priv.pem"
               }
             )
           )
  end

  def worker_with_wrong_settings_port() do
    assert match?(
             {:error, _},
             Worker.start_link(
               settings: %Worker.Settings{
                 rtc_min_port: 1000,
                 rtc_max_port: 999
               }
             )
           )
  end

  def update_settings_succeeds() do
    {:ok, worker} = Worker.start_link()

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
      Worker.start_link(
        settings: %Worker.Settings{
          log_level: :debug
        }
      )

    assert match?(%{"routerIds" => []}, Worker.dump(worker))
    Mediasoup.Worker.close(worker)
  end

  def close_event() do
    {:ok, worker} = Worker.start_link()

    Worker.event(worker, self())
    Worker.close(worker)

    assert_receive {:on_close}
  end

  def close_router() do
    {:ok, worker} = Worker.start_link()

    {:ok, router} =
      Worker.create_router(worker, %{
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

    Mediasoup.Router.close(router)

    refute Worker.closed?(worker)
  end
end

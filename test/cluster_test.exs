defmodule ClusterTest do
  use ExUnit.Case
  alias Mediasoup.{Worker, Router, WebRtcTransport, Consumer, Producer}

  setup_all do
    nodes =
      LocalCluster.start_nodes(:spawn, 1,
        files: [
          __ENV__.file
        ]
      )

    %{nodes: nodes}
  end

  @tag :cluster
  test "pipe_to_router_succeeds_with_audio ", %{nodes: [node1]} do
    caller = self()

    Node.spawn(node1, fn ->
      send(caller, Worker.start_link())
      Process.sleep(50000)
    end)

    worker =
      receive do
        {:ok, worker} -> worker
      end

    IntegrateTest.PipeTransportTest.pipe_to_router_succeeds_with_audio(worker)
  end

  @tag :cluster
  test "pipe ", %{nodes: [node1]} do
    {_worker, _worker2, router1, router2, transport1, _transport2} = init(node1)

    {:ok, audio_producer} = WebRtcTransport.produce(transport1, audio_producer_options())

    {:ok, %{pipe_consumer: pipe_consumer, pipe_producer: pipe_producer}} =
      Router.pipe_producer_to_router(router1, audio_producer.id, %Router.PipeToRouterOptions{
        router: router2
      })

    assert 2 == Router.dump(router1)["transportIds"] |> length
    assert 2 == Router.dump(router2)["transportIds"] |> length

    assert "audio" == pipe_consumer.kind
    refute pipe_consumer.rtp_parameters["mid"]

    assert [
             %{
               "mimeType" => "audio/opus",
               "payloadType" => 100,
               "clockRate" => 48000,
               "channels" => 2,
               "parameters" => %{
                 "bar" => "333",
                 "foo" => "222.222",
                 "usedtx" => 1,
                 "useinbandfec" => 1
               },
               "rtcpFeedback" => []
             }
           ] === pipe_consumer.rtp_parameters["codecs"]

    assert [
             %{
               "encrypt" => false,
               "id" => 10,
               "uri" => "urn:ietf:params:rtp-hdrext:ssrc-audio-level"
             }
           ] === pipe_consumer.rtp_parameters["headerExtensions"]

    assert "pipe" == pipe_consumer.type

    assert Consumer.paused?(pipe_consumer) === false
    assert Consumer.producer_paused?(pipe_consumer) === false

    assert Consumer.score(pipe_consumer) === %{
             "producerScore" => 10,
             "producerScores" => [0],
             "score" => 10
           }

    {:ok, pipe_producer} = Mediasoup.PipedProducer.into_producer(pipe_producer)
    assert pipe_producer.id === audio_producer.id
    assert "audio" === pipe_producer.kind
    refute pipe_producer.rtp_parameters["mid"]

    assert [
             %{
               "mimeType" => "audio/opus",
               "payloadType" => 100,
               "clockRate" => 48000,
               "channels" => 2,
               "parameters" => %{
                 "bar" => "333",
                 "foo" => "222.222",
                 "usedtx" => 1,
                 "useinbandfec" => 1
               },
               "rtcpFeedback" => []
             }
           ] === pipe_producer.rtp_parameters["codecs"]

    assert [
             %{
               "encrypt" => false,
               "id" => 10,
               "uri" => "urn:ietf:params:rtp-hdrext:ssrc-audio-level"
             }
           ] === pipe_producer.rtp_parameters["headerExtensions"]

    assert Producer.paused?(pipe_producer) === false
  end

  @tag :cluster
  test "get_remote_node_ip", %{nodes: [node1]} do
    {:ok, remote_ip} = Mediasoup.Utility.get_remote_node_ip(Node.self(), node1)
    refute remote_ip == "127.0.0.1"
  end

  def init(node1) do
    caller = self()

    Node.spawn(node1, fn ->
      send(caller, Worker.start_link())
      Process.sleep(50000)
    end)

    worker =
      receive do
        {:ok, worker} -> worker
      end

    {:ok, worker2} = Worker.start_link()

    {:ok, router1} =
      Worker.create_router(worker, %{
        mediaCodecs: media_codecs()
      })

    {:ok, router2} =
      Worker.create_router(worker2, %{
        mediaCodecs: media_codecs()
      })

    {:ok, transport1} =
      Router.create_webrtc_transport(router1, %{
        listenIps: {
          %{
            ip: "127.0.0.1"
          }
        }
      })

    {:ok, transport2} =
      Router.create_webrtc_transport(router2, %{
        listenIps: {
          %{
            ip: "127.0.0.1"
          }
        }
      })

    {worker, worker2, router1, router2, transport1, transport2}
  end

  def media_codecs() do
    {
      %{
        kind: "audio",
        mimeType: "audio/opus",
        clockRate: 48000,
        channels: 2,
        parameters: %{"foo" => "bar"},
        rtcpFeedback: []
      },
      %{
        kind: "video",
        mimeType: "video/VP8",
        clockRate: 90000,
        parameters: %{},
        rtcpFeedback: []
      }
    }
  end

  def audio_producer_options() do
    %{
      kind: "audio",
      rtpParameters: %{
        mid: "AUDIO",
        codecs:
          {%{
             mimeType: "audio/opus",
             payloadType: 111,
             clockRate: 48000,
             channels: 2,
             parameters: %{
               "useinbandfec" => 1,
               "usedtx" => 1,
               "foo" => "222.222",
               "bar" => "333"
             },
             rtcpFeedback: []
           }},
        headerExtensions: {
          %{
            uri: "urn:ietf:params:rtp-hdrext:sdes:mid",
            id: 10,
            encrypt: false
          },
          %{
            uri: "urn:ietf:params:rtp-hdrext:ssrc-audio-level",
            id: 12,
            encrypt: false
          }
        },
        encodings:
          {%{
             ssrc: 11_111_111
           }},
        rtcp: %{
          cname: "FOOBAR",
          reducedSize: true
        }
      }
    }
  end
end

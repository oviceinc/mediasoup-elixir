defmodule IntegrateTest.PipeTransportTest do
  @moduledoc """
  test for Consumer with dializer check
  """
  import ExUnit.Assertions
  alias Mediasoup.{WebRtcTransport, Producer, Worker, Router, Consumer}

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

  def video_producer_options() do
    %{
      kind: "video",
      rtpParameters: %{
        mid: "VIDEO",
        codecs:
          {%{
             mimeType: "video/VP8",
             payloadType: 112,
             clockRate: 90000,
             parameters: %{
               "packetization-mode" => 1,
               "profile-level-id" => "4d0032"
             },
             rtcpFeedback: [
               %{type: "nack"},
               %{type: "nack", parameter: "pli"},
               %{type: "goog-remb"}
             ]
           },
           %{
             mimeType: "video/rtx",
             payloadType: 113,
             clockRate: 90000,
             parameters: %{
               "apt" => 112
             },
             rtcpFeedback: []
           }},
        headerExtensions: [
          %{
            uri: "urn:ietf:params:rtp-hdrext:sdes:mid",
            id: 10,
            encrypt: false
          },
          %{
            uri: "urn:ietf:params:rtp-hdrext:sdes:mid",
            id: 10,
            encrypt: false
          },
          %{
            uri: "urn:3gpp:video-orientation",
            id: 13,
            encrypt: false
          }
        ],
        encodings: [
          %{
            ssrc: 22_222_222,
            rtx: %{ssrc: 22_222_223}
          },
          %{
            ssrc: 22_222_224,
            rtx: %{ssrc: 22_222_225}
          },
          %{
            ssrc: 22_222_226,
            rtx: %{ssrc: 22_222_227}
          },
          %{
            ssrc: 22_222_228,
            rtx: %{ssrc: 22_222_229}
          }
        ],
        rtcp: %{
          cname: "FOOBAR",
          reducedSize: true
        }
      }
    }
  end

  def consumer_device_capabilities() do
    %{
      codecs:
        {%{
           kind: "audio",
           mimeType: "audio/opus",
           preferredPayloadType: 100,
           clockRate: 48000,
           channels: 2,
           parameters: %{},
           rtcpFeedback: []
         },
         %{
           kind: "video",
           mimeType: "video/VP8",
           preferredPayloadType: 101,
           clockRate: 90000,
           parameters: %{},
           rtcpFeedback: [
             %{type: "nack"},
             %{type: "ccm", parameter: "fir"},
             %{type: "transport-cc"}
           ]
         },
         %{
           kind: "video",
           mimeType: "video/rtx",
           payloadType: 102,
           clockRate: 90000,
           parameters: %{
             "apt" => 101
           },
           rtcpFeedback: []
         }},
      headerExtensions: {
        %{
          kind: "video",
          uri: "http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time",
          preferredId: 4,
          preferredEncrypt: false,
          direction: "sendrecv"
        },
        %{
          kind: "video",
          uri: "http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01",
          preferredId: 5,
          preferredEncrypt: false,
          direction: "sendrecv"
        },
        %{
          kind: "audio",
          uri: "urn:ietf:params:rtp-hdrext:ssrc-audio-level",
          preferredId: 10,
          preferredEncrypt: false,
          direction: "sendrecv"
        }
      },
      fecMechanisms: {}
    }
  end

  def init() do
    {:ok, worker} = Mediasoup.create_worker()

    Worker.event(worker, self())

    {:ok, router1} =
      Worker.create_router(worker, %{
        mediaCodecs: media_codecs()
      })

    {:ok, router2} =
      Worker.create_router(worker, %{
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

    {worker, router1, router2, transport1, transport2}
  end

  def pipe_to_router_succeeds_with_audio() do
    {_worker, router1, router2, transport1, _transport2} = init()

    {:ok, audio_producer} = WebRtcTransport.produce(transport1, audio_producer_options())

    {:ok, %{pipe_consumer: pipe_consumer}} =
      Router.pipe_producer_to_router(router1, audio_producer.id, %Router.PipeToRouterOptions{
        router: router2
      })

    assert 2 == Mediasoup.Router.dump(router1)["transportIds"] |> length
    assert 2 == Mediasoup.Router.dump(router2)["transportIds"] |> length

    assert "audio" == pipe_consumer.kind
    assert nil == pipe_consumer.rtp_parameters["mid"]

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

    """
    # currently PipedProducer not implemented.
    assert pipe_producer.id === audio_producer.id
    assert "audio" === pipe_producer.kind
    #  assert nil == pipe_producer.rtp_parameters["mid"]

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
    """
  end

  def pipe_to_router_succeeds_with_video() do
    {_worker, router1, router2, transport1, _transport2} = init()
    {:ok, audio_producer} = WebRtcTransport.produce(transport1, audio_producer_options())

    {:ok, _} =
      Router.pipe_producer_to_router(router1, audio_producer.id, %Router.PipeToRouterOptions{
        router: router2
      })

    {:ok, video_producer} = WebRtcTransport.produce(transport1, video_producer_options())
    # Pause the videoProducer.
    assert {:ok} === Producer.pause(video_producer)

    {:ok, %{pipe_consumer: pipe_consumer}} =
      Router.pipe_producer_to_router(router1, video_producer.id, %Router.PipeToRouterOptions{
        router: router2
      })

    assert 2 == Mediasoup.Router.dump(router1)["transportIds"] |> length
    assert 2 == Mediasoup.Router.dump(router2)["transportIds"] |> length

    assert "video" == pipe_consumer.kind
    assert nil == pipe_consumer.rtp_parameters["mid"]

    assert [
             %{
               "clockRate" => 90000,
               "mimeType" => "video/VP8",
               "parameters" => %{"packetization-mode" => 1, "profile-level-id" => "4d0032"},
               "payloadType" => 101,
               "rtcpFeedback" => [
                 %{"parameter" => "pli", "type" => "nack"},
                 %{"parameter" => "fir", "type" => "ccm"}
               ]
             }
           ] === pipe_consumer.rtp_parameters["codecs"]

    assert [
             %{
               "encrypt" => false,
               "id" => 6,
               "uri" => "http://tools.ietf.org/html/draft-ietf-avtext-framemarking-07"
             },
             %{"encrypt" => false, "id" => 7, "uri" => "urn:ietf:params:rtp-hdrext:framemarking"},
             %{"encrypt" => false, "id" => 11, "uri" => "urn:3gpp:video-orientation"},
             %{"encrypt" => false, "id" => 12, "uri" => "urn:ietf:params:rtp-hdrext:toffset"}
           ] === pipe_consumer.rtp_parameters["headerExtensions"]

    assert "pipe" == pipe_consumer.type

    assert Consumer.paused?(pipe_consumer) === false
    assert Consumer.producer_paused?(pipe_consumer) === true

    assert Consumer.score(pipe_consumer) === %{
             "producerScore" => 10,
             "producerScores" => [0, 0, 0, 0],
             "score" => 10
           }

    """
    # currently PipedProducer not implemented.
    assert pipe_producer.id === video_producer.id
    assert "video" === pipe_producer.kind
    #  assert nil == pipe_producer.rtp_parameters["mid"]

    assert [
             %{
               "clockRate" => 90000,
               "mimeType" => "video/H264",
               "parameters" => %{"packetization-mode" => 1, "profile-level-id" => "4d0032"},
               "payloadType" => 103,
               "rtcpFeedback" => [
                 %{"parameter" => "pli", "type" => "nack"},
                 %{"parameter" => "fir", "type" => "ccm"}
               ]
             }
           ] === pipe_producer.rtp_parameters["codecs"]

    assert [
             %{
               "encrypt" => false,
               "id" => 6,
               "uri" => "http://tools.ietf.org/html/draft-ietf-avtext-framemarking-07"
             },
             %{"encrypt" => false, "id" => 7, "uri" => "urn:ietf:params:rtp-hdrext:framemarking"},
             %{"encrypt" => false, "id" => 11, "uri" => "urn:3gpp:video-orientation"},
             %{"encrypt" => false, "id" => 12, "uri" => "urn:ietf:params:rtp-hdrext:toffset"}
           ] === pipe_producer.rtp_parameters["headerExtensions"]

    assert Producer.paused?(pipe_producer) === true
    """
  end

  def consume_for_pipe_producer_succeeds() do
    {_worker, router1, router2, transport1, transport2} = init()

    {:ok, video_producer} = WebRtcTransport.produce(transport1, video_producer_options())
    # Pause the videoProducer.
    {:ok} = Producer.pause(video_producer)

    {:ok, _} =
      Router.pipe_producer_to_router(router1, video_producer.id, %Router.PipeToRouterOptions{
        router: router2
      })

    {:ok, video_consumer} =
      WebRtcTransport.consume(transport2, %{
        producerId: video_producer.id,
        rtpCapabilities: consumer_device_capabilities()
      })

    assert "video" == video_consumer.kind
    assert "0" == video_consumer.rtp_parameters["mid"]

    assert [
             %{
               "clockRate" => 90000,
               "mimeType" => "video/VP8",
               "parameters" => %{"packetization-mode" => 1, "profile-level-id" => "4d0032"},
               "payloadType" => 101,
               "rtcpFeedback" => [
                 %{"parameter" => "", "type" => "nack"},
                 %{"parameter" => "fir", "type" => "ccm"},
                 %{"parameter" => "", "type" => "transport-cc"}
               ]
             },
             %{
               "clockRate" => 90000,
               "mimeType" => "video/rtx",
               "parameters" => %{"apt" => 101},
               "payloadType" => 102,
               "rtcpFeedback" => []
             }
           ] === video_consumer.rtp_parameters["codecs"]

    assert [
             %{
               "encrypt" => false,
               "id" => 4,
               "uri" => "http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time"
             },
             %{
               "encrypt" => false,
               "id" => 5,
               "uri" =>
                 "http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01"
             }
           ] === video_consumer.rtp_parameters["headerExtensions"]

    assert 1 === video_consumer.rtp_parameters["encodings"] |> length
    [encoding] = video_consumer.rtp_parameters["encodings"]
    assert nil != encoding["ssrc"]
    assert nil != encoding["rtx"]
  end

  def producer_pause_resume_are_transmitted_to_pipe_consumer() do
    {_worker, router1, router2, transport1, transport2} = init()

    {:ok, video_producer} = WebRtcTransport.produce(transport1, video_producer_options())
    # Pause the videoProducer.
    {:ok} = Producer.pause(video_producer)

    {:ok, _} =
      Router.pipe_producer_to_router(router1, video_producer.id, %Router.PipeToRouterOptions{
        router: router2
      })

    {:ok, video_consumer} =
      WebRtcTransport.consume(transport2, %{
        producerId: video_producer.id,
        rtpCapabilities: consumer_device_capabilities()
      })

    assert true == video_producer |> Producer.paused?()
    assert true == video_consumer |> Consumer.producer_paused?()
    assert false == video_consumer |> Consumer.paused?()

    Consumer.event(video_consumer, self())

    Producer.resume(video_producer)

    assert_receive {:on_producer_resume}

    assert false == video_consumer |> Consumer.producer_paused?()
    assert false == video_consumer |> Consumer.paused?()

    Producer.pause(video_producer)

    assert_receive {:on_producer_pause}

    assert true == video_consumer |> Consumer.producer_paused?()
    assert false == video_consumer |> Consumer.paused?()
  end

  def pipe_to_router_called_twice_generates_single_pair() do
    {worker, _router1, _router2, _transport1, _transport2} = init()

    {:ok, router_a} =
      Worker.create_router(worker, %{
        mediaCodecs: media_codecs()
      })

    {:ok, router_b} =
      Worker.create_router(worker, %{
        mediaCodecs: media_codecs()
      })

    {:ok, transport1} =
      Router.create_webrtc_transport(router_a, %{
        listenIps: {
          %{
            ip: "127.0.0.1"
          }
        },
        enable_sctp: true
      })

    {:ok, transport2} =
      Router.create_webrtc_transport(router_a, %{
        listenIps: {
          %{
            ip: "127.0.0.1"
          }
        },
        enable_sctp: true
      })

    {:ok, audio_producer1} = WebRtcTransport.produce(transport1, audio_producer_options())
    {:ok, audio_producer2} = WebRtcTransport.produce(transport2, audio_producer_options())

    Router.pipe_producer_to_router(router_a, audio_producer1.id, %Router.PipeToRouterOptions{
      router: router_b
    })

    Router.pipe_producer_to_router(router_a, audio_producer2.id, %Router.PipeToRouterOptions{
      router: router_b
    })

    assert 3 == Mediasoup.Router.dump(router_a)["transportIds"] |> length
    assert 1 == Mediasoup.Router.dump(router_b)["transportIds"] |> length
  end
end

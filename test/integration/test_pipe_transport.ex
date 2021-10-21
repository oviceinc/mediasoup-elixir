defmodule IntegrateTest.PipeTransportTest do
  @moduledoc """
  test for Consumer with dializer check
  """
  import ExUnit.Assertions
  alias Mediasoup.{PipeTransport, WebRtcTransport, Transport, Producer, Worker, Router, Consumer}

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

  def init(worker) do
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

  def pipe_to_router_succeeds_with_audio(worker) do
    {_worker, router1, router2, transport1, _transport2} = init(worker)

    {:ok, audio_producer} = WebRtcTransport.produce(transport1, audio_producer_options())

    {:ok, %{pipe_consumer: pipe_consumer, pipe_producer: pipe_producer}} =
      Router.pipe_producer_to_router(router1, audio_producer.id, %Router.PipeToRouterOptions{
        router: router2
      })

    assert 2 == Mediasoup.Router.dump(router1)["transportIds"] |> length
    assert 2 == Mediasoup.Router.dump(router2)["transportIds"] |> length

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

  def pipe_to_router_succeeds_with_video(worker) do
    {_worker, router1, router2, transport1, _transport2} = init(worker)
    {:ok, audio_producer} = WebRtcTransport.produce(transport1, audio_producer_options())

    {:ok, _} =
      Router.pipe_producer_to_router(router1, audio_producer.id, %Router.PipeToRouterOptions{
        router: router2
      })

    {:ok, video_producer} = WebRtcTransport.produce(transport1, video_producer_options())
    # Pause the videoProducer.
    assert {:ok} === Producer.pause(video_producer)

    {:ok, %{pipe_consumer: pipe_consumer, pipe_producer: pipe_producer}} =
      Router.pipe_producer_to_router(router1, video_producer.id, %Router.PipeToRouterOptions{
        router: router2
      })

    assert 2 == Mediasoup.Router.dump(router1)["transportIds"] |> length
    assert 2 == Mediasoup.Router.dump(router2)["transportIds"] |> length

    assert "video" == pipe_consumer.kind
    refute pipe_consumer.rtp_parameters["mid"]

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

    {:ok, pipe_producer} = Mediasoup.PipedProducer.into_producer(pipe_producer)

    assert pipe_producer.id === video_producer.id
    assert "video" === pipe_producer.kind
    refute pipe_producer.rtp_parameters["mid"]

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
  end

  def create_with_fixed_port_succeeds(worker) do
    {_worker, router1, _router2, _transport1, _transport2} = init(worker)

    {:ok, pipe_transport} =
      Router.create_pipe_transport(router1, %PipeTransport.Options{
        listen_ip: %{ip: "127.0.0.1"},
        port: 60_000
      })

    assert match?(%{"localPort" => 60000}, PipeTransport.tuple(pipe_transport))

    assert is_binary(Transport.id(pipe_transport))
    Transport.close(pipe_transport)
    Transport.closed?(pipe_transport)
  end

  def create_with_enable_rtx_succeeds(worker) do
    {_worker, router1, _router2, transport1, _transport2} = init(worker)

    {:ok, pipe_transport} =
      Router.create_pipe_transport(router1, %PipeTransport.Options{
        listen_ip: %{ip: "127.0.0.1"},
        enable_rtx: true
      })

    {:ok, video_producer} = WebRtcTransport.produce(transport1, video_producer_options())
    # Pause the videoProducer.
    {:ok} = Producer.pause(video_producer)

    {:ok, pipe_consumer} =
      Transport.consume(pipe_transport, %Consumer.Options{
        producer_id: video_producer.id,
        rtp_capabilities: consumer_device_capabilities()
      })

    assert "video" == pipe_consumer.kind
    refute pipe_consumer.rtp_parameters["mid"]

    assert [
             %{
               "clockRate" => 90000,
               "mimeType" => "video/VP8",
               "parameters" => %{"packetization-mode" => 1, "profile-level-id" => "4d0032"},
               "payloadType" => 101,
               "rtcpFeedback" => [
                 %{"parameter" => "", "type" => "nack"},
                 %{"parameter" => "pli", "type" => "nack"},
                 %{"parameter" => "fir", "type" => "ccm"}
               ]
             },
             %{
               "clockRate" => 90000,
               "mimeType" => "video/rtx",
               "parameters" => %{"apt" => 101},
               "payloadType" => 102,
               "rtcpFeedback" => []
             }
           ] === pipe_consumer.rtp_parameters["codecs"]

    assert [
             %{
               "encrypt" => false,
               "id" => 6,
               "uri" => "http://tools.ietf.org/html/draft-ietf-avtext-framemarking-07"
             },
             %{
               "encrypt" => false,
               "id" => 7,
               "uri" => "urn:ietf:params:rtp-hdrext:framemarking"
             },
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
  end

  def create_with_enable_srtp_succeeds(worker) do
    {_worker, router1, _router2, _transport1, _transport2} = init(worker)

    {:ok, pipe_transport} =
      Router.create_pipe_transport(router1, %PipeTransport.Options{
        listen_ip: %{ip: "127.0.0.1"},
        enable_srtp: true
      })

    srtp_parameters = PipeTransport.srtp_parameters(pipe_transport)
    assert match?(%{}, srtp_parameters)
    assert String.length(srtp_parameters["keyBase64"]) == 40

    # Missing srtp_parameters.
    {:error, _message} =
      PipeTransport.connect(pipe_transport, %{ip: "127.0.0.2", port: 9999, srtpParameters: nil})

    # Valid srtp_parameters.
    {:ok} =
      PipeTransport.connect(pipe_transport, %{
        ip: "127.0.0.2",
        port: 9999,
        srtpParameters: %{
          cryptoSuite: "AES_CM_128_HMAC_SHA1_80",
          keyBase64: "ZnQ3eWJraDg0d3ZoYzM5cXN1Y2pnaHU5NWxrZTVv"
        }
      })
  end

  def create_with_invalid_srtp_parameters_fails(worker) do
    {_worker, router1, _router2, _transport1, _transport2} = init(worker)

    {:ok, pipe_transport} =
      Router.create_pipe_transport(router1, %PipeTransport.Options{
        listen_ip: %{ip: "127.0.0.1"}
      })

    # No SRTP enabled so passing srtp_parameters must fail.
    {:error, _message} =
      PipeTransport.connect(pipe_transport, %{
        ip: "127.0.0.2",
        port: 9999,
        srtpParameters: %{
          cryptoSuite: "AES_CM_128_HMAC_SHA1_80",
          keyBase64: "ZnQ3eWJraDg0d3ZoYzM5cXN1Y2pnaHU5NWxrZTVv"
        }
      })
  end

  def consume_for_pipe_producer_succeeds(worker) do
    {_worker, router1, router2, transport1, transport2} = init(worker)

    {:ok, video_producer} = WebRtcTransport.produce(transport1, video_producer_options())
    # Pause the videoProducer.
    {:ok} = Producer.pause(video_producer)

    {:ok, _} =
      Router.pipe_producer_to_router(router1, video_producer.id, %Router.PipeToRouterOptions{
        router: router2
      })

    {:ok, video_consumer} =
      Transport.consume(transport2, %{
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

  def producer_pause_resume_are_transmitted_to_pipe_consumer(worker) do
    {_worker, router1, router2, transport1, transport2} = init(worker)

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

  def pipe_to_router_called_twice_generates_single_pair(worker) do
    {worker, _router1, _router2, _transport1, _transport2} = init(worker)

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

  def pipe_produce_consume(worker) do
    {_worker, router1, router2, transport1, transport2} = init(worker)

    {:ok, video_producer} = WebRtcTransport.produce(transport1, video_producer_options())
    # Pause the videoProducer.
    {:ok} = Producer.pause(video_producer)

    {:ok, pipe_transport_local} =
      Router.create_pipe_transport(router1, %PipeTransport.Options{
        listen_ip: %{ip: "127.0.0.1"}
      })

    {:ok, pipe_transport_remote} =
      Router.create_pipe_transport(router2, %PipeTransport.Options{
        listen_ip: %{ip: "127.0.0.1"}
      })

    %{"localPort" => remote_port, "localIp" => remote_ip} =
      PipeTransport.tuple(pipe_transport_remote)

    %{"localPort" => local_port, "localIp" => local_ip} =
      PipeTransport.tuple(pipe_transport_local)

    {:ok} = PipeTransport.connect(pipe_transport_local, %{ip: remote_ip, port: remote_port})
    {:ok} = PipeTransport.connect(pipe_transport_remote, %{ip: local_ip, port: local_port})

    {:ok, pipe_consumer} =
      Transport.consume(pipe_transport_local, %Consumer.Options{
        producer_id: video_producer.id,
        rtp_capabilities: consumer_device_capabilities()
      })

    {:ok, _pipe_producer} =
      Transport.produce(pipe_transport_remote, %Producer.Options{
        id: video_producer.id,
        kind: pipe_consumer.kind,
        rtp_parameters: pipe_consumer.rtp_parameters,
        paused: Consumer.paused?(pipe_consumer)
      })

    {:ok, video_consumer} =
      Transport.consume(transport2, %Consumer.Options{
        producer_id: video_producer.id,
        rtp_capabilities: consumer_device_capabilities()
      })

    refute Transport.sctp_parameters(pipe_transport_local)
    refute Transport.sctp_state(pipe_transport_local)
    assert Transport.get_stats(pipe_transport_local)

    assert PipeTransport.dump(pipe_transport_local)
    PipeTransport.event(pipe_transport_local, self())

    assert "video" == video_consumer.kind
    assert "0" == video_consumer.rtp_parameters["mid"]

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
  end

  def pipe_produce_consume_with_map(worker) do
    {_worker, router1, _router2, transport1, _transport2} = init(worker)

    {:ok, pipe_transport} =
      Router.create_pipe_transport(router1, %PipeTransport.Options{
        listen_ip: %{ip: "127.0.0.1"},
        enable_rtx: true
      })

    {:ok, video_producer} = WebRtcTransport.produce(transport1, video_producer_options())
    # Pause the videoProducer.
    {:ok} = Producer.pause(video_producer)

    {:ok, pipe_consumer} =
      Transport.consume(pipe_transport, %{
        producerId: video_producer.id,
        rtpCapabilities: consumer_device_capabilities()
      })

    assert "video" == pipe_consumer.kind
    refute pipe_consumer.rtp_parameters["mid"]

    {:ok, _pipe_producer} =
      Transport.produce(pipe_transport, %{
        kind: pipe_consumer.kind,
        rtpParameters: pipe_consumer.rtp_parameters
      })
  end

  def multiple_pipe_to_router(worker) do
    {_worker, router1, router2, transport1, _transport2} = init(worker)

    {:ok, router3} =
      Worker.create_router(worker, %{
        mediaCodecs: media_codecs()
      })

    {:ok, audio_producer} = WebRtcTransport.produce(transport1, audio_producer_options())

    {:ok, _} =
      Router.pipe_producer_to_router(router1, audio_producer.id, %Router.PipeToRouterOptions{
        router: router2
      })

    {:ok, video_producer} = WebRtcTransport.produce(transport1, video_producer_options())
    # Pause the videoProducer.
    assert {:ok} === Producer.pause(video_producer)

    {:ok, _} =
      Router.pipe_producer_to_router(router1, video_producer.id, %Router.PipeToRouterOptions{
        router: router2
      })

    {:ok, _} =
      Router.pipe_producer_to_router(router1, video_producer.id, %Router.PipeToRouterOptions{
        router: router3
      })

    assert 3 == Mediasoup.Router.dump(router1)["transportIds"] |> length
    assert 2 == Mediasoup.Router.dump(router2)["transportIds"] |> length
    assert 1 == Mediasoup.Router.dump(router3)["transportIds"] |> length
  end

  def close_event(worker) do
    {_worker, router1, _router2, _transport1, _transport2} = init(worker)

    {:ok, pipe_transport} =
      Router.create_pipe_transport(router1, %PipeTransport.Options{
        listen_ip: %{ip: "127.0.0.1"}
      })

    Mediasoup.Transport.event(pipe_transport, self())
    Mediasoup.Transport.close(pipe_transport)

    assert_receive {:on_close}
  end

  def close_router_event(worker) do
    {_worker, router1, _router2, _transport1, _transport2} = init(worker)

    {:ok, pipe_transport} =
      Router.create_pipe_transport(router1, %PipeTransport.Options{
        listen_ip: %{ip: "127.0.0.1"}
      })

    Mediasoup.Transport.event(pipe_transport, self())
    Mediasoup.Router.close(router1)
    assert Mediasoup.Transport.closed?(pipe_transport)
    assert_receive {:on_close}
  end

  def producer_close_are_transmitted_to_pipe_consumer(worker) do
    {_worker, router1, router2, transport1, _transport2} = init(worker)

    {:ok, audio_producer} = WebRtcTransport.produce(transport1, audio_producer_options())

    {:ok, _} =
      Router.pipe_producer_to_router(router1, audio_producer.id, %Router.PipeToRouterOptions{
        router: router2
      })

    {:ok, video_producer} = WebRtcTransport.produce(transport1, video_producer_options())
    # Pause the videoProducer.
    assert {:ok} === Producer.pause(video_producer)

    {:ok, %{pipe_consumer: pipe_consumer, pipe_producer: pipe_producer}} =
      Router.pipe_producer_to_router(router1, video_producer.id, %Router.PipeToRouterOptions{
        router: router2
      })

    {:ok, pipe_producer} = Mediasoup.PipedProducer.into_producer(pipe_producer)

    Mediasoup.Consumer.close(pipe_consumer)

    Process.sleep(100)
    assert Mediasoup.Consumer.closed?(pipe_consumer)
    assert Mediasoup.Producer.closed?(pipe_producer)
  end

  def consumer_close_are_transmitted_to_pipe_consumer(worker) do
    {_worker, router1, router2, transport1, _transport2} = init(worker)

    {:ok, audio_producer} = WebRtcTransport.produce(transport1, audio_producer_options())

    {:ok, _} =
      Router.pipe_producer_to_router(router1, audio_producer.id, %Router.PipeToRouterOptions{
        router: router2
      })

    {:ok, video_producer} = WebRtcTransport.produce(transport1, video_producer_options())
    # Pause the videoProducer.
    assert {:ok} === Producer.pause(video_producer)

    {:ok, %{pipe_consumer: pipe_consumer, pipe_producer: pipe_producer}} =
      Router.pipe_producer_to_router(router1, video_producer.id, %Router.PipeToRouterOptions{
        router: router2
      })

    {:ok, pipe_producer} = Mediasoup.PipedProducer.into_producer(pipe_producer)

    Mediasoup.Producer.close(pipe_producer)

    Process.sleep(100)
    assert Mediasoup.Consumer.closed?(pipe_consumer)
    assert Mediasoup.Producer.closed?(pipe_producer)
  end
end

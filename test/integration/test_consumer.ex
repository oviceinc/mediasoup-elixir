defmodule IntegrateTest.ConsumerTest do
  @moduledoc """
  test for Consumer with dializer check
  """
  import ExUnit.Assertions
  alias Mediasoup.{WebRtcTransport, Producer, Router, Consumer}

  def media_codecs() do
    [
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
      },
      %{
        kind: "video",
        mimeType: "video/H264",
        clockRate: 90000,
        parameters: %{
          "level-asymmetry-allowed" => 1,
          "packetization-mode" => 1,
          "profile-level-id" => "4d0032",
          "foo" => "bar"
        },
        rtcpFeedback: []
      }
    ]
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
             mimeType: "video/H264",
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
        headerExtensions: {
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
        },
        encodings:
          {%{
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
           }},
        rtcp: %{
          cname: "FOOBAR",
          reducedSize: true
        }
      }
    }
  end

  def consumer_device_capabilities() do
    %{
      codecs: [
        %{
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
          mimeType: "video/H264",
          preferredPayloadType: 101,
          clockRate: 90000,
          parameters: %{
            "level-asymmetry-allowed" => 1,
            "packetization-mode" => 1,
            "profile-level-id" => "4d0032"
          },
          rtcpFeedback: [
            %{type: "nack"},
            %{type: "nack", parameter: "pli"},
            %{type: "ccm", parameter: "fir"},
            %{type: "goog-remb"}
          ]
        },
        %{
          kind: "video",
          mimeType: "video/rtx",
          payloadType: 102,
          clockRate: 90000,
          parameters: %{
            "apt" => 112
          },
          rtcpFeedback: []
        }
      ],
      headerExtensions: [
        %{
          kind: "audio",
          uri: "urn:ietf:params:rtp-hdrext:sdes:mid",
          preferredId: 1,
          preferredEncrypt: false,
          direction: "sendrecv"
        },
        %{
          kind: "video",
          uri: "urn:ietf:params:rtp-hdrext:sdes:mid",
          preferredId: 1,
          preferredEncrypt: false,
          direction: "sendrecv"
        },
        %{
          kind: "video",
          uri: "urn:ietf:params:rtp-hdrext:sdes:rtp-stream-id",
          preferredId: 2,
          preferredEncrypt: false,
          direction: "sendrecv"
        },
        %{
          kind: "audio",
          uri: "http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time",
          preferredId: 4,
          preferredEncrypt: false,
          direction: "sendrecv"
        },
        %{
          kind: "video",
          uri: "http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time",
          preferredId: 4,
          preferredEncrypt: false,
          direction: "sendrecv"
        },
        %{
          kind: "audio",
          uri: "urn:ietf:params:rtp-hdrext:ssrc-audio-level",
          preferredId: 10,
          preferredEncrypt: false,
          direction: "sendrecv"
        },
        %{
          kind: "video",
          uri: "urn:3gpp:video-orientation",
          preferredId: 11,
          preferredEncrypt: false,
          direction: "sendrecv"
        },
        %{
          kind: "video",
          uri: "urn:ietf:params:rtp-hdrext:toffset",
          preferredId: 12,
          preferredEncrypt: false,
          direction: "sendrecv"
        }
      ],
      fecMechanisms: []
    }
  end

  def init(worker) do
    alias Mediasoup.{Worker, Router}

    Worker.event(worker, self())

    {:ok, router} =
      Worker.create_router(worker, %{
        mediaCodecs: media_codecs()
      })

    {:ok, transport_1} =
      Router.create_webrtc_transport(router, %{
        listenIps: [
          %{
            ip: "127.0.0.1"
          }
        ]
      })

    {:ok, transport_2} =
      Router.create_webrtc_transport(router, %{
        listenIps: [
          %{
            ip: "127.0.0.1"
          }
        ]
      })

    {worker, router, transport_1, transport_2}
  end

  def consume_succeeds(worker) do
    {worker, router, transport_1, transport_2} = init(worker)

    {:ok, audio_producer} = WebRtcTransport.produce(transport_1, audio_producer_options())
    {:ok, video_producer} = WebRtcTransport.produce(transport_1, video_producer_options())

    assert {:ok} === WebRtcTransport.event(transport_2, self())
    assert {:ok} === Producer.pause(video_producer)

    ## Audio
    assert true === Router.can_consume?(router, audio_producer.id, consumer_device_capabilities())

    {:ok, audio_consumer} =
      WebRtcTransport.consume(transport_2, %{
        producerId: audio_producer |> Producer.id(),
        rtpCapabilities: consumer_device_capabilities()
      })

    assert audio_producer |> Producer.id() === audio_consumer |> Consumer.producer_id()
    assert "audio" === audio_consumer.kind
    assert "0" === audio_consumer.rtp_parameters["mid"]

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
           ] === audio_consumer.rtp_parameters["codecs"]

    assert Consumer.closed?(audio_consumer) === false
    assert Consumer.paused?(audio_consumer) === false
    assert Consumer.producer_paused?(audio_consumer) === false
    assert Consumer.priority(audio_consumer) === 1

    assert Consumer.score(audio_consumer) === %{
             "producerScore" => 0,
             "producerScores" => [0],
             "score" => 10
           }

    assert Consumer.preferred_layers(audio_consumer) === nil
    assert Consumer.current_layers(audio_consumer) === nil

    assert Router.dump(router)["mapProducerIdConsumerIds"] === %{
             (audio_producer |> Producer.id()) => [audio_consumer |> Consumer.id()],
             (video_producer |> Producer.id()) => []
           }

    assert WebRtcTransport.dump(transport_2)["producerIds"] === []
    assert WebRtcTransport.dump(transport_2)["consumerIds"] === [audio_consumer.id]

    ## Video
    assert true === Router.can_consume?(router, video_producer.id, consumer_device_capabilities())

    {:ok, video_consumer} =
      WebRtcTransport.consume(transport_2, %{
        producerId: video_producer.id,
        rtpCapabilities: consumer_device_capabilities()
      })

    assert video_producer.id === Consumer.producer_id(video_consumer)
    assert "video" === Consumer.kind(video_consumer)
    assert "1" === Consumer.rtp_parameters(video_consumer)["mid"]

    assert [
             %{
               "mimeType" => "video/H264",
               "payloadType" => 103,
               "clockRate" => 90000,
               "parameters" => %{
                 "packetization-mode" => 1,
                 "profile-level-id" => "4d0032"
               },
               "rtcpFeedback" => [
                 %{"type" => "nack", "parameter" => ""},
                 %{"type" => "nack", "parameter" => "pli"},
                 %{"type" => "ccm", "parameter" => "fir"},
                 %{"type" => "goog-remb", "parameter" => ""}
               ]
             },
             %{
               "mimeType" => "video/rtx",
               "payloadType" => 104,
               "clockRate" => 90000,
               "parameters" => %{
                 "apt" => 103
               },
               "rtcpFeedback" => []
             }
           ] === video_consumer.rtp_parameters["codecs"]

    assert Consumer.closed?(video_consumer) === false
    assert Consumer.paused?(video_consumer) === false
    assert Consumer.producer_paused?(video_consumer) === true
    assert Consumer.priority(video_consumer) === 1

    assert Consumer.score(video_consumer) === %{
             "producerScore" => 0,
             "producerScores" => [0, 0, 0, 0],
             "score" => 10
           }

    assert Consumer.preferred_layers(video_consumer) === %{
             "spatialLayer" => 3,
             "temporalLayer" => 0
           }

    assert Consumer.current_layers(video_consumer) === nil

    assert Router.dump(router)["mapProducerIdConsumerIds"] === %{
             audio_producer.id => [audio_consumer.id],
             video_producer.id => [video_consumer.id]
           }

    assert WebRtcTransport.dump(transport_2)["producerIds"] === []

    assert WebRtcTransport.dump(transport_2)["consumerIds"] |> Enum.member?(video_consumer.id)
    assert WebRtcTransport.dump(transport_2)["consumerIds"] |> Enum.member?(audio_consumer.id)

    ## Video pipe
    assert true === Router.can_consume?(router, video_producer.id, consumer_device_capabilities())

    {:ok, video_pipe_consumer} =
      WebRtcTransport.consume(transport_2, %{
        producerId: video_producer.id,
        rtpCapabilities: consumer_device_capabilities(),
        pipe: true
      })

    assert video_producer.id === video_pipe_consumer.producer_id
    assert "video" === video_pipe_consumer.kind
    assert nil === video_pipe_consumer.rtp_parameters["mid"]

    assert [
             %{
               "mimeType" => "video/H264",
               "payloadType" => 103,
               "clockRate" => 90000,
               "parameters" => %{
                 "packetization-mode" => 1,
                 "profile-level-id" => "4d0032"
               },
               "rtcpFeedback" => [
                 %{"type" => "nack", "parameter" => ""},
                 %{"type" => "nack", "parameter" => "pli"},
                 %{"type" => "ccm", "parameter" => "fir"},
                 %{"type" => "goog-remb", "parameter" => ""}
               ]
             },
             %{
               "mimeType" => "video/rtx",
               "payloadType" => 104,
               "clockRate" => 90000,
               "parameters" => %{
                 "apt" => 103
               },
               "rtcpFeedback" => []
             }
           ] === video_pipe_consumer.rtp_parameters["codecs"]

    assert Consumer.closed?(video_pipe_consumer) === false
    assert Consumer.paused?(video_pipe_consumer) === false
    assert Consumer.producer_paused?(video_pipe_consumer) === true
    assert Consumer.priority(video_pipe_consumer) === 1

    assert Consumer.score(video_pipe_consumer) === %{
             "producerScore" => 10,
             "producerScores" => [0, 0, 0, 0],
             "score" => 10
           }

    assert Consumer.preferred_layers(video_pipe_consumer) === nil
    assert Consumer.current_layers(video_pipe_consumer) === nil

    video_producer_ids = Router.dump(router)["mapProducerIdConsumerIds"][video_producer.id]
    assert video_consumer.id in video_producer_ids
    assert video_pipe_consumer.id in video_producer_ids

    assert WebRtcTransport.dump(transport_2)["producerIds"] === []
    assert audio_producer.id in WebRtcTransport.dump(transport_1)["producerIds"]
    assert video_producer.id in WebRtcTransport.dump(transport_1)["producerIds"]

    consumer_ids = WebRtcTransport.dump(transport_2)["consumerIds"]
    assert video_consumer.id in consumer_ids
    assert video_pipe_consumer.id in consumer_ids
    assert audio_consumer.id in consumer_ids

    Mediasoup.WebRtcTransport.close(transport_1)
    Mediasoup.WebRtcTransport.close(transport_2)
    Mediasoup.Router.close(router)
    Mediasoup.Worker.close(worker)
  end

  def consume_incompatible_rtp_capabilities(worker) do
    {worker, router, transport_1, transport_2} = init(worker)
    {:ok, audio_producer} = WebRtcTransport.produce(transport_1, audio_producer_options())

    incompatible_device_capabilities = %{
      codecs: [
        %{
          kind: "audio",
          mimeType: "audio/ISAC",
          preferredPayloadType: 100,
          clockRate: 32000,
          channels: 1,
          parameters: %{},
          rtcpFeedback: []
        }
      ],
      headerExtensions: [],
      fecMechanisms: []
    }

    assert false ===
             Router.can_consume?(router, audio_producer.id, incompatible_device_capabilities)

    {:error, _message} =
      WebRtcTransport.consume(transport_2, %{
        producerId: audio_producer.id,
        rtpCapabilities: incompatible_device_capabilities
      })

    incompatible_device_capabilities2 = %{
      codecs: {},
      headerExtensions: {},
      fecMechanisms: {}
    }

    assert false ===
             Router.can_consume?(router, audio_producer.id, incompatible_device_capabilities2)

    {:error, _message} =
      WebRtcTransport.consume(transport_2, %{
        producerId: audio_producer.id,
        rtpCapabilities: incompatible_device_capabilities2
      })

    Mediasoup.WebRtcTransport.close(transport_1)
    Mediasoup.WebRtcTransport.close(transport_2)
    Mediasoup.Router.close(router)
    Mediasoup.Worker.close(worker)
  end

  def dump_succeeds(worker) do
    {worker, router, transport_1, transport_2} = init(worker)
    {:ok, audio_producer} = WebRtcTransport.produce(transport_1, audio_producer_options())
    {:ok, video_producer} = WebRtcTransport.produce(transport_1, video_producer_options())

    assert {:ok} === Producer.pause(video_producer)

    assert true === Router.can_consume?(router, audio_producer.id, consumer_device_capabilities())

    {:ok, audio_consumer} =
      WebRtcTransport.consume(transport_2, %{
        producerId: audio_producer.id,
        rtpCapabilities: consumer_device_capabilities()
      })

    assert {:ok} === Producer.pause(audio_producer)

    dump = Consumer.dump(audio_consumer)

    assert dump["producerId"] === audio_consumer.producer_id
    assert dump["kind"] === audio_consumer.kind

    assert dump["rtpParameters"]["codecs"] == [
             %{
               "channels" => 2,
               "clockRate" => 48000,
               "mimeType" => "audio/opus",
               "parameters" => %{
                 "bar" => "333",
                 "foo" => "222.222",
                 "usedtx" => 1,
                 "useinbandfec" => 1
               },
               "payloadType" => 100,
               "rtcpFeedback" => []
             }
           ]

    assert dump["rtpParameters"]["headerExtensions"] == [
             %{"encrypt" => false, "id" => 1, "uri" => "urn:ietf:params:rtp-hdrext:sdes:mid"},
             %{
               "encrypt" => false,
               "id" => 4,
               "uri" => "http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time"
             },
             %{
               "encrypt" => false,
               "id" => 10,
               "uri" => "urn:ietf:params:rtp-hdrext:ssrc-audio-level"
             }
           ]

    ssrc = List.first(audio_consumer.rtp_parameters["encodings"])["ssrc"]
    assert dump["rtpParameters"]["encodings"] == [%{"codecPayloadType" => 100, "ssrc" => ssrc}]

    Mediasoup.WebRtcTransport.close(transport_1)
    Mediasoup.WebRtcTransport.close(transport_2)
    Mediasoup.Router.close(router)
    Mediasoup.Worker.close(worker)
  end

  def get_stats_succeeds(worker) do
    {worker, router, transport_1, transport_2} = init(worker)
    {:ok, audio_producer} = WebRtcTransport.produce(transport_1, audio_producer_options())
    assert true === Router.can_consume?(router, audio_producer.id, consumer_device_capabilities())

    {:ok, audio_consumer} =
      WebRtcTransport.consume(transport_2, %{
        producerId: audio_producer.id,
        rtpCapabilities: consumer_device_capabilities()
      })

    assert {:ok} === Producer.pause(audio_producer)

    assert false == Consumer.closed?(audio_consumer)

    [consumer_stat | _producer_stat] = Consumer.get_stats(audio_consumer)

    assert consumer_stat["kind"] == "audio"
    assert consumer_stat["mimeType"] == "audio/opus"

    {:ok, video_producer} = WebRtcTransport.produce(transport_1, video_producer_options())
    assert {:ok} === Producer.pause(video_producer)

    {:ok, video_consumer} =
      WebRtcTransport.consume(transport_2, %{
        producerId: video_producer.id,
        rtpCapabilities: consumer_device_capabilities()
      })

    [consumer_stat | _producer_stat] = Consumer.get_stats(video_consumer)

    assert "simulcast" == Consumer.type(video_consumer)

    assert consumer_stat["kind"] == "video"
    assert consumer_stat["mimeType"] == "video/H264"
    Mediasoup.WebRtcTransport.close(transport_1)
    Mediasoup.WebRtcTransport.close(transport_2)
    Mediasoup.Router.close(router)
    Mediasoup.Worker.close(worker)
  end

  def enable_rtx_option(worker) do
    {worker, router, transport_1, transport_2} = init(worker)
    {:ok, video_producer} = WebRtcTransport.produce(transport_1, video_producer_options())
    assert true === Router.can_consume?(router, video_producer.id, consumer_device_capabilities())

    {:ok, video_consumer} =
      WebRtcTransport.consume(transport_1, %Consumer.Options{
        producer_id: video_producer.id,
        rtp_capabilities: consumer_device_capabilities(),
        enable_rtx: true
      })

    {:ok, video_consumer2} =
      WebRtcTransport.consume(transport_2, %Consumer.Options{
        producer_id: video_producer.id,
        rtp_capabilities: consumer_device_capabilities(),
        enable_rtx: false
      })

    assert List.first(Consumer.dump(video_consumer)["rtpStreams"])["params"]["useNack"] == true
    assert List.first(Consumer.dump(video_consumer2)["rtpStreams"])["params"]["useNack"] == false

    Mediasoup.WebRtcTransport.close(transport_1)
    Mediasoup.WebRtcTransport.close(transport_2)
    Mediasoup.Router.close(router)
    Mediasoup.Worker.close(worker)
  end

  def close(worker) do
    {_worker, _router, transport_1, transport_2} = init(worker)
    {:ok, audio_producer} = WebRtcTransport.produce(transport_1, audio_producer_options())

    {:ok, audio_consumer} =
      WebRtcTransport.consume(transport_2, %{
        producerId: audio_producer.id,
        rtpCapabilities: consumer_device_capabilities()
      })

    assert Consumer.closed?(audio_consumer) == false
    Consumer.close(audio_consumer)
    assert Consumer.closed?(audio_consumer) == true
  end

  def pause_resume_succeeds(worker) do
    {worker, router, transport_1, transport_2} = init(worker)
    {:ok, audio_producer} = WebRtcTransport.produce(transport_1, audio_producer_options())

    {:ok, audio_consumer} =
      WebRtcTransport.consume(transport_2, %{
        producerId: audio_producer.id,
        rtpCapabilities: consumer_device_capabilities()
      })

    assert {:ok} === Producer.pause(audio_producer)

    Consumer.pause(audio_consumer)

    consumer_dump = Consumer.dump(audio_consumer)
    assert consumer_dump["paused"] == true

    Consumer.resume(audio_consumer)

    consumer_dump = Consumer.dump(audio_consumer)
    assert consumer_dump["paused"] == false
    Mediasoup.WebRtcTransport.close(transport_1)
    Mediasoup.WebRtcTransport.close(transport_2)
    Mediasoup.Router.close(router)
    Mediasoup.Worker.close(worker)
  end

  def set_preferred_layers_succeeds(worker) do
    {worker, router, transport_1, transport_2} = init(worker)
    {:ok, audio_producer} = WebRtcTransport.produce(transport_1, audio_producer_options())

    {:ok, audio_consumer} =
      WebRtcTransport.consume(transport_2, %{
        producerId: audio_producer.id,
        rtpCapabilities: consumer_device_capabilities()
      })

    Consumer.set_preferred_layers(audio_consumer, %{
      spatialLayer: 1,
      temporalLayer: 1
    })

    assert Consumer.preferred_layers(audio_consumer) === nil

    {:ok, video_producer} = WebRtcTransport.produce(transport_1, video_producer_options())

    {:ok, video_consumer} =
      WebRtcTransport.consume(transport_2, %{
        producerId: video_producer.id,
        rtpCapabilities: consumer_device_capabilities(),
        paused: true,
        preferredLayers: %{
          spatialLayer: 12
        }
      })

    Consumer.set_preferred_layers(video_consumer, %{
      spatialLayer: 2,
      temporalLayer: 3
    })

    assert Consumer.preferred_layers(video_consumer) === %{
             "spatialLayer" => 2,
             "temporalLayer" => 0
           }

    Mediasoup.WebRtcTransport.close(transport_1)
    Mediasoup.WebRtcTransport.close(transport_2)
    Mediasoup.Router.close(router)
    Mediasoup.Worker.close(worker)
  end

  def unset_priority_succeeds(worker) do
    {worker, router, transport_1, transport_2} = init(worker)
    {:ok, video_producer} = WebRtcTransport.produce(transport_1, video_producer_options())

    {:ok, video_consumer} =
      WebRtcTransport.consume(transport_2, %{
        producerId: video_producer.id,
        rtpCapabilities: consumer_device_capabilities(),
        paused: true,
        preferredLayers: %{
          spatialLayer: 12
        }
      })

    assert {:ok} === Producer.pause(video_producer)

    {:ok} = Consumer.set_priority(video_consumer, 2)
    assert Consumer.priority(video_consumer) == 2
    Consumer.unset_priority(video_consumer)
    assert Consumer.priority(video_consumer) == 1
    Mediasoup.WebRtcTransport.close(transport_1)
    Mediasoup.WebRtcTransport.close(transport_2)
    Mediasoup.Router.close(router)
    Mediasoup.Worker.close(worker)
  end

  def request_key_frame(worker) do
    {_worker, _router, transport_1, transport_2} = init(worker)
    {:ok, audio_producer} = WebRtcTransport.produce(transport_1, audio_producer_options())

    {:ok, audio_consumer} =
      WebRtcTransport.consume(transport_2, %{
        producerId: audio_producer.id,
        rtpCapabilities: consumer_device_capabilities()
      })

    Consumer.request_key_frame(audio_consumer)
  end

  def close_event(worker) do
    {_worker, router, transport_1, transport_2} = init(worker)
    {:ok, audio_producer} = WebRtcTransport.produce(transport_1, audio_producer_options())

    {:ok, audio_consumer} =
      WebRtcTransport.consume(transport_2, %{
        producerId: audio_producer.id,
        rtpCapabilities: consumer_device_capabilities()
      })

    Consumer.event(audio_consumer, self())
    Consumer.close(audio_consumer)

    assert_receive {:on_close}

    # wait for notify close to router
    Process.sleep(50)
    router_dump = Router.dump(router)

    assert router_dump["mapProducerIdConsumerIds"] === %{audio_producer.id => []}

    transport_1_dump = WebRtcTransport.dump(transport_1)
    assert transport_1_dump["producerIds"] == [audio_producer.id]
    assert transport_1_dump["consumerIds"] == []
  end
end

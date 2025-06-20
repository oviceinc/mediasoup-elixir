defmodule IntegrateTest.ProducerTest do
  use ExUnit.Case

  @moduledoc """
  test for Producer with dializer check
  """
  import ExUnit.Assertions
  alias Mediasoup.{Producer, WebRtcTransport, Router, Worker}

  defp media_codecs() do
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
    }
  end

  def audio_producer_options() do
    %{
      kind: "audio",
      rtpParameters: %{
        mid: "AUDIO",
        codecs: [
          %{
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
          }
        ],
        headerExtensions: [
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
        ],
        encodings: [
          %{
            ssrc: 11_111_111,
            codecPayloadType: 111
          }
        ],
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
        codecs: [
          %{
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
          }
        ],
        headerExtensions: [
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

  @spec produce_succeeds(pid()) :: true
  def produce_succeeds(worker) do
    {_worker, router, transport_1, transport_2} = init(worker)

    {:ok, audio_producer} = WebRtcTransport.produce(transport_1, audio_producer_options())

    assert Producer.closed?(audio_producer) === false
    assert Producer.kind(audio_producer) === "audio"
    assert Producer.type(audio_producer) === "simple"
    assert Producer.paused?(audio_producer) === false
    assert Producer.score(audio_producer) === []

    router_dump = Router.dump(router)

    assert router_dump["mapProducerIdConsumerIds"] === %{
             audio_producer.id => []
           }

    transport_1_dump = WebRtcTransport.dump(transport_1)
    assert transport_1_dump["producerIds"] === [audio_producer.id]
    assert transport_1_dump["consumerIds"] === []
    Producer.close(audio_producer)

    {:ok, video_producer} = WebRtcTransport.produce(transport_2, video_producer_options())

    assert Producer.closed?(video_producer) === false
    assert Producer.kind(video_producer) === "video"
    assert Producer.type(video_producer) === "simulcast"
    assert Producer.paused?(video_producer) === false
    assert Producer.score(video_producer) === []

    router_dump = Router.dump(router)

    assert router_dump["mapProducerIdConsumerIds"] === %{
             video_producer.id => []
           }

    transport_2_dump = WebRtcTransport.dump(transport_2)
    assert transport_2_dump["producerIds"] === [video_producer.id]
    assert transport_2_dump["consumerIds"] === []
  end

  def close(worker) do
    {_worker, _router, transport_1, _transport_2} = init(worker)

    {:ok, audio_producer} = WebRtcTransport.produce(transport_1, audio_producer_options())
    assert Producer.closed?(audio_producer) == false
    Producer.close(audio_producer)
    assert Producer.closed?(audio_producer) == true
  end

  def produce_wrong_arguments(worker) do
    {_worker, _router, transport_1, _transport_2} = init(worker)

    Mediasoup.Worker.update_settings(worker, %Mediasoup.Worker.UpdateableSettings{
      log_level: :none,
      log_tags: []
    })

    # Empty rtp_parameters.codecs.
    {:error, message} =
      WebRtcTransport.produce(transport_1, %{
        kind: "audio",
        rtpParameters: %{
          mid: "AUDIO",
          codecs: [],
          headerExtensions: [],
          encodings: [],
          rtcp: %{
            cname: "FOOBAR",
            reducedSize: true
          }
        }
      })

    "Request to worker failed:" <> _ = message

    # Wrong apt in RTX codec.
    {:error, message} =
      WebRtcTransport.produce(
        transport_1,
        %{
          kind: "video",
          rtpParameters: %{
            mid: "VIDEO",
            codecs: [
              %{
                mimeType: "video/H264",
                payloadType: 112,
                clockRate: 90000,
                parameters: %{
                  "packetization-mode" => 1,
                  "profile-level-id" => "4d0032"
                },
                rtcpFeedback: []
              },
              %{
                mimeType: "video/rtx",
                payloadType: 113,
                clockRate: 90000,
                parameters: %{
                  "apt" => 111
                },
                rtcpFeedback: []
              }
            ],
            headerExtensions: [],
            encodings: [
              %{
                ssrc: 6666,
                rtx: %{ssrc: 6667}
              }
            ],
            rtcp: %{
              cname: "video-1",
              reducedSize: true
            }
          }
        }
      )

    "RTP mapping error:" <> _ = message
  end

  def produce_unsupported_codecs(worker) do
    {_worker, _router, transport_1, _transport_2} = init(worker)

    {:error, message} =
      WebRtcTransport.produce(transport_1, %{
        kind: "audio",
        rtpParameters: %{
          mid: "AUDIO",
          codecs: [
            %{
              kind: "audio",
              mimeType: "audio/ISAC",
              payloadType: 108,
              clockRate: 32000,
              channels: 1,
              parameters: %{},
              rtcpFeedback: []
            }
          ],
          headerExtensions: [],
          encodings: [
            %{
              ssrc: 1111
            }
          ],
          rtcp: %{
            cname: "audio",
            reducedSize: true
          }
        }
      })

    "RTP mapping error:" <> _ = message

    # Invalid H264 profile-level-id.

    {:error, message} =
      WebRtcTransport.produce(
        transport_1,
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
                   "profile-level-id" => "CHICKEN"
                 },
                 rtcpFeedback: []
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
            encodings: [
              %{
                ssrc: 6666,
                rtx: %{ssrc: 6667}
              }
            ],
            rtcp: %{
              cname: "FOOBAR",
              reducedSize: true
            }
          }
        }
      )

    "RTP mapping error:" <> _ = message
  end

  def produce_already_used_mid_ssrc(worker) do
    {_worker, _router, transport_1, transport_2} = init(worker)

    {:ok, _first_producer} = WebRtcTransport.produce(transport_1, audio_producer_options())

    Mediasoup.Worker.update_settings(worker, %Mediasoup.Worker.UpdateableSettings{
      log_level: :none,
      log_tags: []
    })

    {:error, message} =
      WebRtcTransport.produce(transport_1, %{
        kind: "audio",
        rtpParameters: %{
          mid: "AUDIO",
          codecs:
            {%{
               mimeType: "audio/opus",
               payloadType: 0,
               clockRate: 48000,
               channels: 2,
               parameters: %{},
               rtcpFeedback: []
             }},
          headerExtensions: [],
          encodings: [
            %{
              ssrc: 33_333_333
            }
          ],
          rtcp: %{
            cname: "audio-2",
            reducedSize: true
          }
        }
      })

    "Request to worker failed:" <> _ = message

    {:ok, _first_producer} = WebRtcTransport.produce(transport_2, video_producer_options())

    {:error, message} =
      WebRtcTransport.produce(
        transport_2,
        %{
          kind: "video",
          rtpParameters: %{
            mid: "VIDEO2",
            codecs:
              {%{
                 mimeType: "video/VP8",
                 payloadType: 112,
                 clockRate: 90000,
                 parameters: %{},
                 rtcpFeedback: []
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
            headerExtensions: [],
            encodings: [
              %{
                ssrc: 22_222_222,
                rtx: %{ssrc: 6667}
              }
            ],
            rtcp: %{
              cname: "FOOBAR",
              reducedSize: true
            }
          }
        }
      )

    "Request to worker failed:" <> _ = message
  end

  def produce_no_mid_single_encoding_without_dir_or_ssrc(worker) do
    {_worker, _router, transport_1, _transport_2} = init(worker)

    Mediasoup.Worker.update_settings(worker, %Mediasoup.Worker.UpdateableSettings{
      log_level: :none,
      log_tags: []
    })

    {:error, message} =
      WebRtcTransport.produce(transport_1, %{
        kind: "audio",
        rtpParameters: %{
          codecs: [
            %{
              kind: "audio",
              mimeType: "audio/opus",
              payloadType: 111,
              clockRate: 48_000,
              channels: 2,
              parameters: %{},
              rtcpFeedback: []
            }
          ],
          headerExtensions: [],
          encodings: [],
          rtcp: %{
            cname: "audio-2",
            reducedSize: true
          }
        }
      })

    "Request to worker failed:" <> _ = message
  end

  def dump_succeeds(worker) do
    {_worker, _router, transport_1, transport_2} = init(worker)
    {:ok, audio_producer} = WebRtcTransport.produce(transport_1, audio_producer_options())

    dump = Producer.dump(audio_producer)

    assert dump["id"] == Producer.id(audio_producer)
    assert dump["kind"] == Producer.kind(audio_producer)

    assert dump["rtpParameters"] == %{
             "codecs" => [
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
                 "payloadType" => 111,
                 "rtcpFeedback" => []
               }
             ],
             "encodings" => [%{"codecPayloadType" => 111, "ssrc" => 11_111_111}],
             "headerExtensions" => [
               %{"encrypt" => false, "id" => 10, "uri" => "urn:ietf:params:rtp-hdrext:sdes:mid"},
               %{
                 "encrypt" => false,
                 "id" => 12,
                 "uri" => "urn:ietf:params:rtp-hdrext:ssrc-audio-level"
               }
             ],
             "mid" => "AUDIO",
             "rtcp" => %{"cname" => "FOOBAR", "reducedSize" => true}
           }

    assert Producer.rtp_parameters(audio_producer) == dump["rtpParameters"]
    assert dump["type"] == "simple"

    {:ok, video_producer} = WebRtcTransport.produce(transport_2, video_producer_options())

    dump = Producer.dump(video_producer)

    assert dump["id"] == Producer.id(video_producer)
    assert dump["kind"] == Producer.kind(video_producer)

    assert dump["rtpParameters"] == %{
             "codecs" => [
               %{
                 "clockRate" => 90000,
                 "mimeType" => "video/H264",
                 "parameters" => %{"packetization-mode" => 1, "profile-level-id" => "4d0032"},
                 "payloadType" => 112,
                 "rtcpFeedback" => [
                   %{"type" => "nack", "parameter" => ""},
                   %{"parameter" => "pli", "type" => "nack"},
                   %{"type" => "goog-remb", "parameter" => ""}
                 ]
               },
               %{
                 "clockRate" => 90000,
                 "mimeType" => "video/rtx",
                 "parameters" => %{"apt" => 112},
                 "payloadType" => 113,
                 "rtcpFeedback" => []
               }
             ],
             "encodings" => [
               %{
                 "rtx" => %{"ssrc" => 22_222_223},
                 "ssrc" => 22_222_222,
                 "codecPayloadType" => 112
               },
               %{
                 "rtx" => %{"ssrc" => 22_222_225},
                 "ssrc" => 22_222_224,
                 "codecPayloadType" => 112
               },
               %{
                 "rtx" => %{"ssrc" => 22_222_227},
                 "ssrc" => 22_222_226,
                 "codecPayloadType" => 112
               },
               %{
                 "rtx" => %{"ssrc" => 22_222_229},
                 "ssrc" => 22_222_228,
                 "codecPayloadType" => 112
               }
             ],
             "headerExtensions" => [
               %{"encrypt" => false, "id" => 10, "uri" => "urn:ietf:params:rtp-hdrext:sdes:mid"},
               %{"encrypt" => false, "id" => 13, "uri" => "urn:3gpp:video-orientation"}
             ],
             "mid" => "VIDEO",
             "rtcp" => %{"cname" => "FOOBAR", "reducedSize" => true}
           }

    assert dump["type"] == "simulcast"
  end

  def get_stats_succeeds(worker) do
    {_worker, _router, transport_1, transport_2} = init(worker)
    {:ok, audio_producer} = WebRtcTransport.produce(transport_1, audio_producer_options())

    stats = Producer.get_stats(audio_producer)
    assert [] == stats

    {:ok, video_producer} = WebRtcTransport.produce(transport_2, video_producer_options())

    stats = Producer.get_stats(video_producer)
    assert [] == stats
  end

  def pause_resume_succeeds(worker) do
    {_worker, _router, transport_1, _transport_2} = init(worker)
    {:ok, audio_producer} = WebRtcTransport.produce(transport_1, audio_producer_options())

    Producer.pause(audio_producer)
    dump = Producer.dump(audio_producer)

    assert dump["paused"]

    Producer.resume(audio_producer)
    dump = Producer.dump(audio_producer)
    assert dump["paused"] == false
  end

  def close_event(worker) do
    {_worker, router, transport_1, _transport_2} = init(worker)
    {:ok, audio_producer} = WebRtcTransport.produce(transport_1, audio_producer_options())

    Producer.event(audio_producer, self())
    Producer.close(audio_producer)

    assert_receive {:on_close}

    # wait for the router to be notified of close
    Process.sleep(10)

    router_dump = Router.dump(router)

    assert router_dump["mapProducerIdConsumerIds"] === %{}

    transport_1_dump = WebRtcTransport.dump(transport_1)
    assert transport_1_dump["producerIds"] == []
    assert transport_1_dump["consumerIds"] == []
  end

  def producer_event(worker) do
    {_worker, _router, transport_1, _transport_2} = init(worker)

    {:ok, audio_producer} = WebRtcTransport.produce(transport_1, audio_producer_options())

    # Register event handler
    assert {:ok} = Producer.event(audio_producer, self(), [:on_score])

    # Send internal event directly to test the handler
    send(audio_producer.pid, {:nif_internal_event, :on_score, [%{"score" => 10}]})

    # Verify event received
    assert_receive {:on_score, [%{"score" => 10}]}, 5000

    # Cleanup
    Producer.close(audio_producer)
    WebRtcTransport.close(transport_1)
  end
end

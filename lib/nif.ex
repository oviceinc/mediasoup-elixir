defmodule Mediasoup.Nif do
  @moduledoc """
  Nif interface for mediasoup
  Do not use directly
  """
  use Rustler, otp_app: :mediasoup_elixir, crate: :mediasoup_elixir

  alias Mediasoup.{Worker, Router}

  # async nif functions

  ## worker with async
  defp create_worker_async(), do: :erlang.nif_error(:nif_not_loaded)
  defp create_worker_async(_option), do: :erlang.nif_error(:nif_not_loaded)
  defp worker_create_router_async(_worker, _option), do: :erlang.nif_error(:nif_not_loaded)
  defp worker_dump_async(_worker), do: :erlang.nif_error(:nif_not_loaded)
  defp worker_update_settings_async(_worker, _option), do: :erlang.nif_error(:nif_not_loaded)

  ## router with async
  def router_create_pipe_transport_async(
        _reference,
        _option
      ),
      do: :erlang.nif_error(:nif_not_loaded)

  def router_create_webrtc_transport_async(_router, _option),
    do: :erlang.nif_error(:nif_not_loaded)

  def router_dump_async(_router), do: :erlang.nif_error(:nif_not_loaded)

  ## consumer with async
  defp consumer_get_stats_async(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  defp consumer_pause_async(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  defp consumer_resume_async(_consumer), do: :erlang.nif_error(:nif_not_loaded)

  defp consumer_set_preferred_layers_async(_consumer, _referred_layers),
    do: :erlang.nif_error(:nif_not_loaded)

  defp consumer_set_priority_async(_consumer, _priority), do: :erlang.nif_error(:nif_not_loaded)
  defp consumer_unset_priority_async(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  defp consumer_request_key_frame_async(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  defp consumer_dump_async(_consumer), do: :erlang.nif_error(:nif_not_loaded)

  # construct worker
  def create_worker(), do: create_worker_async() |> handle_async_nif_result()
  def create_worker(option), do: create_worker_async(option) |> handle_async_nif_result()

  # worker
  @spec worker_create_router(reference, Router.create_option()) :: {:ok, reference()} | {:error}
  def worker_create_router(worker, option),
    do: worker_create_router_async(worker, option) |> handle_async_nif_result()

  @spec worker_id(reference) :: String.t()
  def worker_id(_worker), do: :erlang.nif_error(:nif_not_loaded)
  @spec worker_close(reference) :: {:ok} | {:error}
  def worker_close(_worker), do: :erlang.nif_error(:nif_not_loaded)
  @spec worker_event(reference, pid, [atom()]) :: {:ok} | {:error}
  def worker_event(_worker, _pid, _event_types), do: :erlang.nif_error(:nif_not_loaded)
  @spec worker_closed(reference) :: boolean
  def worker_closed(_worker), do: :erlang.nif_error(:nif_not_loaded)
  @spec worker_update_settings(reference, Worker.update_option()) :: {:ok} | {:error}
  def worker_update_settings(worker, option),
    do: worker_update_settings_async(worker, option) |> handle_async_nif_result()

  @spec worker_dump(reference) :: map | {:error}
  def worker_dump(worker),
    do: worker_dump_async(worker) |> handle_async_nif_result() |> unwrap_ok()

  # router
  @spec router_id(reference) :: String.t()
  def router_id(_router), do: :erlang.nif_error(:nif_not_loaded)
  @spec router_close(reference) :: {:ok} | {:error}
  def router_close(_router), do: :erlang.nif_error(:nif_not_loaded)

  def router_closed(_router), do: :erlang.nif_error(:nif_not_loaded)

  def router_create_pipe_transport(
        router,
        option
      ),
      do: router_create_pipe_transport_async(router, option) |> handle_async_nif_result()

  @spec router_create_webrtc_transport(reference, map) ::
          {:ok, reference()} | {:error, String.t()}
  def router_create_webrtc_transport(router, option),
    do: router_create_webrtc_transport_async(router, option) |> handle_async_nif_result()

  @spec router_can_consume(reference, String.t(), Router.rtpCapabilities()) :: boolean
  def router_can_consume(_router, _producer_id, _rtp_capabilities),
    do: :erlang.nif_error(:nif_not_loaded)

  @spec router_rtp_capabilities(reference) :: Router.rtpCapabilities()
  def router_rtp_capabilities(_router), do: :erlang.nif_error(:nif_not_loaded)

  @spec router_event(reference, pid, [atom()]) :: {:ok} | {:error}
  def router_event(_router, _pid, _event_types), do: :erlang.nif_error(:nif_not_loaded)
  @spec router_dump(reference) :: any
  def router_dump(router),
    do: router_dump_async(router) |> handle_async_nif_result() |> unwrap_ok()

  # webrtc_transport
  @spec webrtc_transport_id(reference) :: String.t()
  def webrtc_transport_id(_transport), do: :erlang.nif_error(:nif_not_loaded)
  @spec webrtc_transport_close(reference) :: {:ok} | {:error}
  def webrtc_transport_close(_transport), do: :erlang.nif_error(:nif_not_loaded)
  @spec webrtc_transport_closed(reference) :: boolean
  def webrtc_transport_closed(_transport), do: :erlang.nif_error(:nif_not_loaded)

  @spec webrtc_transport_consume(reference, any) :: {:ok, reference()} | {:error, String.t()}
  def webrtc_transport_consume(_transport, _option), do: :erlang.nif_error(:nif_not_loaded)
  @spec webrtc_transport_connect(reference, any) :: {:ok} | {:error, String.t()}
  def webrtc_transport_connect(_transport, _option), do: :erlang.nif_error(:nif_not_loaded)
  @spec webrtc_transport_produce(reference, any) :: {:ok, reference()} | {:error, String.t()}
  def webrtc_transport_produce(_transport, _option), do: :erlang.nif_error(:nif_not_loaded)
  def webrtc_transport_ice_parameters(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def webrtc_transport_ice_candidates(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def webrtc_transport_ice_role(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def webrtc_transport_sctp_parameters(_transport), do: :erlang.nif_error(:nif_not_loaded)

  def webrtc_transport_set_max_incoming_bitrate(_transport, _bitrate),
    do: :erlang.nif_error(:nif_not_loaded)

  def webrtc_transport_set_max_outgoing_bitrate(_transport, _bitrate),
    do: :erlang.nif_error(:nif_not_loaded)

  def webrtc_transport_ice_state(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def webrtc_transport_restart_ice(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def webrtc_transport_ice_selected_tuple(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def webrtc_transport_dtls_parameters(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def webrtc_transport_dtls_state(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def webrtc_transport_sctp_state(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def webrtc_transport_get_stats(_transport), do: :erlang.nif_error(:nif_not_loaded)
  @spec webrtc_transport_event(reference, pid, [atom()]) :: {:ok} | {:error}
  def webrtc_transport_event(_transport, _pid, _event_types),
    do: :erlang.nif_error(:nif_not_loaded)

  def webrtc_transport_dump(_transport), do: :erlang.nif_error(:nif_not_loaded)

  # pipe_transport
  def pipe_transport_id(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def pipe_transport_close(_transport), do: :erlang.nif_error(:nif_not_loaded)
  @spec pipe_transport_closed(reference) :: boolean
  def pipe_transport_closed(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def pipe_transport_consume(_transport, _option), do: :erlang.nif_error(:nif_not_loaded)
  def pipe_transport_connect(_transport, _option), do: :erlang.nif_error(:nif_not_loaded)
  def pipe_transport_produce(_transport, _option), do: :erlang.nif_error(:nif_not_loaded)
  def pipe_transport_get_stats(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def pipe_transport_tuple(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def pipe_transport_sctp_parameters(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def pipe_transport_sctp_state(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def pipe_transport_srtp_parameters(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def pipe_transport_dump(_transport), do: :erlang.nif_error(:nif_not_loaded)

  def pipe_transport_event(_transport, _pid, _event_types),
    do: :erlang.nif_error(:nif_not_loaded)

  # consumer
  @spec consumer_id(reference) :: String.t()
  def consumer_id(_consumer), do: :erlang.nif_error(:nif_not_loaded)

  @spec consumer_producer_id(reference) :: String.t()
  def consumer_producer_id(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec consumer_kind(reference) :: String.t()
  def consumer_kind(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec consumer_type(reference) :: String.t()
  def consumer_type(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec consumer_rtp_parameters(reference) :: term
  def consumer_rtp_parameters(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec consumer_close(reference) :: {:ok} | {:error}
  def consumer_close(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec consumer_closed(reference) :: boolean
  def consumer_closed(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec consumer_event(reference, pid, [atom()]) :: {:ok} | {:error}
  def consumer_event(_consumer, _pid, _event_types), do: :erlang.nif_error(:nif_not_loaded)
  @spec consumer_paused(reference) :: boolean
  def consumer_paused(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec consumer_producer_paused(reference) :: boolean
  def consumer_producer_paused(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  def consumer_priority(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  def consumer_score(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  def consumer_preferred_layers(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  def consumer_current_layers(_consumer), do: :erlang.nif_error(:nif_not_loaded)

  def consumer_get_stats(consumer),
    do: consumer_get_stats_async(consumer) |> handle_async_nif_result() |> unwrap_ok()

  def consumer_pause(consumer), do: consumer_pause_async(consumer) |> handle_async_nif_result()
  def consumer_resume(consumer), do: consumer_resume_async(consumer) |> handle_async_nif_result()

  def consumer_set_preferred_layers(consumer, referred_layers),
    do:
      consumer_set_preferred_layers_async(consumer, referred_layers) |> handle_async_nif_result()

  def consumer_set_priority(consumer, priority),
    do: consumer_set_priority_async(consumer, priority) |> handle_async_nif_result()

  def consumer_unset_priority(consumer),
    do: consumer_unset_priority_async(consumer) |> handle_async_nif_result()

  def consumer_request_key_frame(consumer),
    do: consumer_request_key_frame_async(consumer) |> handle_async_nif_result()

  def consumer_dump(consumer),
    do: consumer_dump_async(consumer) |> handle_async_nif_result() |> unwrap_ok()

  # producer
  @spec producer_id(reference) :: String.t()
  def producer_id(_producer), do: :erlang.nif_error(:nif_not_loaded)
  @spec producer_kind(reference) :: String.t()
  def producer_kind(_producer), do: :erlang.nif_error(:nif_not_loaded)
  @spec producer_type(reference) :: String.t()
  def producer_type(_producer), do: :erlang.nif_error(:nif_not_loaded)
  @spec producer_rtp_parameters(reference) :: term()
  def producer_rtp_parameters(_producer), do: :erlang.nif_error(:nif_not_loaded)
  @spec producer_close(reference) :: {:ok} | {:error}
  def producer_close(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec producer_pause(reference) :: {:ok} | {:error}
  def producer_pause(_producer), do: :erlang.nif_error(:nif_not_loaded)
  @spec producer_resume(reference) :: {:ok} | {:error}
  def producer_resume(_producer), do: :erlang.nif_error(:nif_not_loaded)

  @spec producer_closed(reference) :: boolean()
  def producer_closed(_producer), do: :erlang.nif_error(:nif_not_loaded)
  @spec producer_paused(reference) :: boolean() | {:error}
  def producer_paused(_producer), do: :erlang.nif_error(:nif_not_loaded)

  @spec producer_score(reference) :: list() | {:error}
  def producer_score(_producer), do: :erlang.nif_error(:nif_not_loaded)
  @spec producer_get_stats(reference) :: list() | {:error}
  def producer_get_stats(_producer), do: :erlang.nif_error(:nif_not_loaded)

  @spec producer_event(reference, pid, [atom()]) :: {:ok} | {:error}
  def producer_event(_producer, _pid, _event_types), do: :erlang.nif_error(:nif_not_loaded)
  def producer_dump(_producer), do: :erlang.nif_error(:nif_not_loaded)

  defp handle_async_nif_result(result) do
    case result do
      {:ok, result_key} ->
        receive do
          {^result_key, {:ok, {}}} -> {:ok}
          {^result_key, msg} -> msg
        end

      error ->
        error
    end
  end

  defp unwrap_ok({:ok, result}), do: result
  defp unwrap_ok(result), do: result
end

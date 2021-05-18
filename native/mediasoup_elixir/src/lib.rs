mod atoms;
mod consumer;
mod decoder;
mod encoder;
mod json_serde;
mod macros;
mod producer;
mod resource;
mod router;
mod webrtc_transport;
mod worker;

use crate::consumer::{
    consumer_close, consumer_closed, consumer_current_layers, consumer_dump, consumer_event,
    consumer_get_stats, consumer_id, consumer_pause, consumer_paused, consumer_preferred_layers,
    consumer_priority, consumer_producer_paused, consumer_request_key_frame, consumer_resume,
    consumer_score, consumer_set_preferred_layers, consumer_set_priority, consumer_unset_priority,
};
use crate::producer::{
    producer_close, producer_dump, producer_event, producer_id, producer_pause, producer_resume,
};
use crate::resource::DisposableResourceWrapper;
use crate::router::{
    create_webrtc_transport, router_can_consume, router_close, router_dump, router_event,
    router_id, router_rtp_capabilities,
};
use crate::webrtc_transport::{
    webrtc_transport_close, webrtc_transport_connect, webrtc_transport_consume,
    webrtc_transport_dtls_parameters, webrtc_transport_dtls_state, webrtc_transport_dump,
    webrtc_transport_event, webrtc_transport_get_stats, webrtc_transport_ice_candidates,
    webrtc_transport_ice_role, webrtc_transport_ice_selected_tuple, webrtc_transport_ice_state,
    webrtc_transport_id, webrtc_transport_produce, webrtc_transport_restart_ice,
    webrtc_transport_sctp_state, webrtc_transport_set_max_incoming_bitrate,
};
use crate::worker::{
    create_router, create_worker, create_worker_no_arg, worker_close, worker_closed, worker_dump,
    worker_event, worker_id, worker_update_settings,
};

use mediasoup::consumer::Consumer;
use mediasoup::producer::Producer;
use mediasoup::router::Router;
use mediasoup::webrtc_transport::WebRtcTransport;
use mediasoup::worker::Worker;
use rustler::{resource_struct_init, Env, OwnedEnv, Term};

pub fn send_msg_from_other_thread<T>(pid: rustler::Pid, value: T)
where
    T: rustler::Encoder + Send + 'static,
{
    let mut my_env = OwnedEnv::new();
    std::thread::spawn(move || {
        my_env.send_and_clear(&pid, |env| value.encode(env));
    });
}

rustler::rustler_export_nifs! {
    "Elixir.Mediasoup.Nif",
    [
        //
        ("create_worker", 0, create_worker_no_arg),
        ("create_worker", 1, create_worker),


        // worker
        ("worker_id", 1, worker_id),
        ("worker_close", 1, worker_close),
        ("worker_create_router", 2, create_router),
        ("worker_event", 2, worker_event),
        ("worker_closed", 1, worker_closed),
        ("worker_update_settings", 2, worker_update_settings),
        ("worker_dump", 1, worker_dump),

        // router
        ("router_id", 1, router_id),
        ("router_close", 1, router_close),
        ("router_create_webrtc_transport", 2, create_webrtc_transport),
        ("router_can_consume", 3, router_can_consume),
        ("router_rtp_capabilities", 1, router_rtp_capabilities),
        ("router_event", 2, router_event),
        ("router_dump", 1, router_dump),

        // webrtc_transport
        ("webrtc_transport_id", 1, webrtc_transport_id),
        ("webrtc_transport_close", 1, webrtc_transport_close),
        ("webrtc_transport_ice_candidates", 1, webrtc_transport_ice_candidates),
        ("webrtc_transport_ice_role", 1, webrtc_transport_ice_role),
        ("webrtc_transport_consume", 2, webrtc_transport_consume, rustler::SchedulerFlags::DirtyIo),
        ("webrtc_transport_connect", 2, webrtc_transport_connect, rustler::SchedulerFlags::DirtyIo),
        ("webrtc_transport_produce", 2, webrtc_transport_produce, rustler::SchedulerFlags::DirtyIo),
        ("webrtc_transport_set_max_incoming_bitrate", 2, webrtc_transport_set_max_incoming_bitrate),
        ("webrtc_transport_ice_state", 1, webrtc_transport_ice_state),
        ("webrtc_transport_restart_ice", 1, webrtc_transport_restart_ice),
        ("webrtc_transport_ice_selected_tuple", 1, webrtc_transport_ice_selected_tuple),
        ("webrtc_transport_dtls_parameters", 1, webrtc_transport_dtls_parameters),
        ("webrtc_transport_dtls_state", 1, webrtc_transport_dtls_state),
        ("webrtc_transport_sctp_state", 1, webrtc_transport_sctp_state),
        ("webrtc_transport_get_stats", 1, webrtc_transport_get_stats),
        ("webrtc_transport_event", 2, webrtc_transport_event),
        ("webrtc_transport_dump", 1, webrtc_transport_dump),


        // consumer
        ("consumer_id", 1, consumer_id),
        ("consumer_close", 1, consumer_close),
        ("consumer_closed", 1, consumer_closed),
        ("consumer_event", 2, consumer_event),
        ("consumer_dump", 1, consumer_dump),
        ("consumer_paused", 1, consumer_paused),
        ("consumer_producer_paused", 1, consumer_producer_paused),
        ("consumer_priority", 1, consumer_priority),
        ("consumer_score", 1, consumer_score),
        ("consumer_preferred_layers", 1, consumer_preferred_layers),
        ("consumer_current_layers", 1, consumer_current_layers),
        ("consumer_get_stats", 1, consumer_get_stats),
        ("consumer_pause", 1, consumer_pause),
        ("consumer_resume", 1, consumer_resume),
        ("consumer_set_preferred_layers", 2, consumer_set_preferred_layers),
        ("consumer_set_priority", 2, consumer_set_priority),
        ("consumer_unset_priority", 1, consumer_unset_priority),
        ("consumer_request_key_frame", 1, consumer_request_key_frame),

        // producer
        ("producer_id", 1, producer_id),
        ("producer_close", 1, producer_close),
        ("producer_pause", 1, producer_pause),
        ("producer_resume", 1, producer_resume),
        ("producer_event", 2, producer_event),
        ("producer_dump", 1, producer_dump)

    ],
    Some(on_load)
}

fn on_load<'a>(env: Env<'a>, _load_info: Term<'a>) -> bool {
    // This macro will take care of defining and initializing a new resource
    // object type.
    resource_struct_init!(WorkerRef, env);
    resource_struct_init!(RouterRef, env);
    resource_struct_init!(WebRtcTransportRef, env);
    resource_struct_init!(ConsumerRef, env);
    resource_struct_init!(ProducerRef, env);
    true
}

pub type WorkerRef = DisposableResourceWrapper<Worker>;
pub type RouterRef = DisposableResourceWrapper<Router>;
pub type WebRtcTransportRef = DisposableResourceWrapper<WebRtcTransport>;
pub type ConsumerRef = DisposableResourceWrapper<Consumer>;
pub type ProducerRef = DisposableResourceWrapper<Producer>;

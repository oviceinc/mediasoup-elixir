mod atoms;
mod consumer;
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
    piped_producer_into_producer, producer_close, producer_closed, producer_dump, producer_event,
    producer_get_stats, producer_id, producer_pause, producer_paused, producer_resume,
    producer_score,
};
use crate::resource::DisposableResourceWrapper;
use crate::router::{
    router_can_consume, router_close, router_create_webrtc_transport, router_dump, router_event,
    router_id, router_pipe_producer_to_router, router_rtp_capabilities,
};
use crate::webrtc_transport::{
    webrtc_transport_close, webrtc_transport_connect, webrtc_transport_consume,
    webrtc_transport_dtls_parameters, webrtc_transport_dtls_state, webrtc_transport_dump,
    webrtc_transport_event, webrtc_transport_get_stats, webrtc_transport_ice_candidates,
    webrtc_transport_ice_parameters, webrtc_transport_ice_role,
    webrtc_transport_ice_selected_tuple, webrtc_transport_ice_state, webrtc_transport_id,
    webrtc_transport_produce, webrtc_transport_restart_ice, webrtc_transport_sctp_parameters,
    webrtc_transport_sctp_state, webrtc_transport_set_max_incoming_bitrate,
    webrtc_transport_set_max_outgoing_bitrate,
};
use crate::worker::{
    create_worker, create_worker_no_arg, worker_close, worker_closed, worker_create_router,
    worker_dump, worker_event, worker_id, worker_update_settings,
};

use mediasoup::consumer::Consumer;
use mediasoup::producer::{PipedProducer, Producer};
use mediasoup::router::Router;
use mediasoup::webrtc_transport::WebRtcTransport;
use mediasoup::worker::Worker;
use rustler::{Env, LocalPid, OwnedEnv, Term};

pub fn send_msg_from_other_thread<T>(pid: LocalPid, value: T)
where
    T: rustler::Encoder + Send + 'static,
{
    let mut my_env = OwnedEnv::new();
    std::thread::spawn(move || {
        my_env.send_and_clear(&pid, |env| value.encode(env));
    });
}

rustler::init! {
    "Elixir.Mediasoup.Nif",
    [
        //
        create_worker_no_arg,
        create_worker,

        // worker
        worker_id,
        worker_close,
        worker_create_router,
        worker_event,
        worker_closed,
        worker_update_settings,
        worker_dump,

        // router
        router_id,
        router_close,
        router_create_webrtc_transport,
        router_can_consume,
        router_rtp_capabilities,
        router_pipe_producer_to_router,
        router_event,
        router_dump,

        // webrtc_transport
        webrtc_transport_id,
        webrtc_transport_close,
        webrtc_transport_ice_candidates,
        webrtc_transport_ice_role,
        webrtc_transport_consume,
        webrtc_transport_connect,
        webrtc_transport_produce,
        webrtc_transport_set_max_incoming_bitrate,
        webrtc_transport_set_max_outgoing_bitrate,
        webrtc_transport_ice_state,
        webrtc_transport_restart_ice,
        webrtc_transport_ice_selected_tuple,
        webrtc_transport_ice_parameters,
        webrtc_transport_sctp_parameters,
        webrtc_transport_dtls_parameters,
        webrtc_transport_dtls_state,
        webrtc_transport_sctp_state,
        webrtc_transport_get_stats,
        webrtc_transport_event,
        webrtc_transport_dump,


        // consumer
        consumer_id,
        consumer_close,
        consumer_closed,
        consumer_event,
        consumer_dump,
        consumer_paused,
        consumer_producer_paused,
        consumer_priority,
        consumer_score,
        consumer_preferred_layers,
        consumer_current_layers,
        consumer_get_stats,
        consumer_pause,
        consumer_resume,
        consumer_set_preferred_layers,
        consumer_set_priority,
        consumer_unset_priority,
        consumer_request_key_frame,

        // producer
        producer_id,
        producer_close,
        producer_pause,
        producer_resume,
        producer_closed,
        producer_paused,
        producer_score,
        producer_get_stats,
        producer_event,
        producer_dump,
        piped_producer_into_producer

    ],
    load = on_load
}

fn on_load<'a>(env: Env<'a>, _load_info: Term<'a>) -> bool {
    // This macro will take care of defining and initializing a new resource
    // object type.
    rustler::resource!(WorkerRef, env);
    rustler::resource!(RouterRef, env);
    rustler::resource!(WebRtcTransportRef, env);
    rustler::resource!(ConsumerRef, env);
    rustler::resource!(ProducerRef, env);
    rustler::resource!(PipedProducerRef, env);
    true
}

pub type WorkerRef = DisposableResourceWrapper<Worker>;
pub type RouterRef = DisposableResourceWrapper<Router>;
pub type WebRtcTransportRef = DisposableResourceWrapper<WebRtcTransport>;
pub type ConsumerRef = DisposableResourceWrapper<Consumer>;
pub type ProducerRef = DisposableResourceWrapper<Producer>;
pub type PipedProducerRef = DisposableResourceWrapper<PipedProducer>;

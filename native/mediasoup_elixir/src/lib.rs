mod atoms;
mod consumer;
mod data_consumer;
mod data_producer;
mod data_structure;
mod json_serde;
mod logger;
mod macros;
mod pipe_transport;
mod plain_transport;
mod producer;
mod resource;
mod router;
mod task;
mod webrtc_server;
mod webrtc_transport;
mod worker;

use crate::consumer::{
    consumer_close, consumer_closed, consumer_current_layers, consumer_dump, consumer_event,
    consumer_get_stats, consumer_id, consumer_kind, consumer_pause, consumer_paused,
    consumer_preferred_layers, consumer_priority, consumer_producer_id, consumer_producer_paused,
    consumer_request_key_frame, consumer_resume, consumer_rtp_parameters, consumer_score,
    consumer_set_preferred_layers, consumer_set_priority, consumer_type, consumer_unset_priority,
};
use crate::pipe_transport::{
    pipe_transport_close, pipe_transport_closed, pipe_transport_connect, pipe_transport_consume,
    pipe_transport_consume_data, pipe_transport_dump, pipe_transport_event,
    pipe_transport_get_stats, pipe_transport_id, pipe_transport_produce,
    pipe_transport_produce_data, pipe_transport_sctp_parameters, pipe_transport_sctp_state,
    pipe_transport_srtp_parameters, pipe_transport_tuple,
};
use crate::plain_transport::{
    plain_transport_close, plain_transport_closed, plain_transport_connect,
    plain_transport_consume, plain_transport_event, plain_transport_get_stats, plain_transport_id,
    plain_transport_produce, plain_transport_sctp_parameters, plain_transport_sctp_state,
    plain_transport_srtp_parameters, plain_transport_tuple,
};
use crate::producer::{
    producer_close, producer_closed, producer_dump, producer_event, producer_get_stats,
    producer_id, producer_kind, producer_pause, producer_paused, producer_resume,
    producer_rtp_parameters, producer_score, producer_type,
};
use crate::resource::DisposableResourceWrapper;
use crate::router::{
    router_can_consume, router_close, router_closed, router_create_pipe_transport,
    router_create_plain_transport, router_create_webrtc_transport, router_dump, router_event,
    router_id, router_rtp_capabilities,
};
use crate::webrtc_transport::{
    webrtc_transport_close, webrtc_transport_closed, webrtc_transport_connect,
    webrtc_transport_consume, webrtc_transport_consume_data, webrtc_transport_dtls_parameters,
    webrtc_transport_dtls_state, webrtc_transport_dump, webrtc_transport_event,
    webrtc_transport_get_stats, webrtc_transport_ice_candidates, webrtc_transport_ice_parameters,
    webrtc_transport_ice_role, webrtc_transport_ice_selected_tuple, webrtc_transport_ice_state,
    webrtc_transport_id, webrtc_transport_produce, webrtc_transport_produce_data,
    webrtc_transport_restart_ice, webrtc_transport_sctp_parameters, webrtc_transport_sctp_state,
    webrtc_transport_set_max_incoming_bitrate, webrtc_transport_set_max_outgoing_bitrate,
};

use crate::webrtc_server::{
    webrtc_server_close, webrtc_server_closed, webrtc_server_dump, webrtc_server_id,
};

use crate::worker::{
    create_worker, create_worker_no_arg, worker_close, worker_closed, worker_create_router,
    worker_create_webrtc_server, worker_dump, worker_event, worker_global_count, worker_id,
    worker_update_settings,
};

use data_consumer::{
    data_consumer_close, data_consumer_closed, data_consumer_event, data_consumer_id,
    data_consumer_label, data_consumer_producer_id, data_consumer_protocol,
    data_consumer_sctp_stream_parameters, data_consumer_type,
};
use data_producer::{
    data_producer_close, data_producer_closed, data_producer_event, data_producer_id,
    data_producer_sctp_stream_parameters, data_producer_type,
};
use logger::{debug_logger, init_env_logger, set_logger_proxy_process};

use futures_lite::future;
use mediasoup::consumer::Consumer;
use mediasoup::pipe_transport::PipeTransport;
use mediasoup::plain_transport::PlainTransport;
use mediasoup::prelude::{DataConsumer, DataProducer, WebRtcServer};
use mediasoup::producer::Producer;
use mediasoup::router::Router;
use mediasoup::webrtc_transport::WebRtcTransport;
use mediasoup::worker::Worker;
use rustler::{Atom, Encoder, Env, LocalPid, NifResult, OwnedEnv, Term};

pub fn send_msg_from_other_thread<T>(pid: LocalPid, value: T)
where
    T: rustler::Encoder + Send + 'static,
{
    let mut my_env = OwnedEnv::new();
    task::spawn(async move {
        let _ = my_env.send_and_clear(&pid, |env| value.encode(env));
    })
    .detach();
}

pub fn send_async_nif_result<T, E, Fut>(env: Env, future: Fut) -> NifResult<(Atom, Atom)>
where
    T: Encoder,
    E: Encoder,
    Fut: future::Future<Output = Result<T, E>> + Send + 'static,
{
    let pid = env.pid();
    let mut my_env = OwnedEnv::new();
    let result_key = atoms::mediasoup_async_nif_result();
    task::spawn(async move {
        let result = future.await;
        match result {
            Ok(worker) => {
                let _ = my_env
                    .send_and_clear(&pid, |env| (result_key, (atoms::ok(), worker)).encode(env));
            }
            Err(err) => {
                let _ = my_env
                    .send_and_clear(&pid, |env| (result_key, (atoms::error(), err)).encode(env));
            }
        }
    })
    .detach();

    Ok((atoms::ok(), result_key))
}

rustler::init! {
    "Elixir.Mediasoup.Nif",
    [
        //
        create_worker_no_arg,
        create_worker,
        worker_global_count,

        // worker
        worker_id,
        worker_close,
        worker_create_router,
        worker_event,
        worker_closed,
        worker_update_settings,
        worker_create_webrtc_server,
        worker_dump,

        // router
        router_id,
        router_close,
        router_closed,
        router_create_webrtc_transport,
        router_create_plain_transport,
        router_can_consume,
        router_rtp_capabilities,
        router_create_pipe_transport,
        router_event,
        router_dump,


        // webrtc_server
        webrtc_server_id,
        webrtc_server_close,
        webrtc_server_closed,
        webrtc_server_dump,


        // webrtc_transport
        webrtc_transport_id,
        webrtc_transport_close,
        webrtc_transport_closed,
        webrtc_transport_ice_candidates,
        webrtc_transport_ice_role,
        webrtc_transport_consume,
        webrtc_transport_consume_data,
        webrtc_transport_connect,
        webrtc_transport_produce,
        webrtc_transport_produce_data,
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


        // pipe_transport
        pipe_transport_id,
        pipe_transport_close,
        pipe_transport_closed,
        pipe_transport_tuple,
        pipe_transport_consume,
        pipe_transport_connect,
        pipe_transport_produce,
        pipe_transport_get_stats,
        pipe_transport_sctp_parameters,
        pipe_transport_sctp_state,
        pipe_transport_srtp_parameters,
        pipe_transport_dump,
        pipe_transport_event,
        pipe_transport_produce_data,
        pipe_transport_consume_data,

        // plain transport
        plain_transport_id,
        plain_transport_tuple,
        plain_transport_sctp_parameters,
        plain_transport_sctp_state,
        plain_transport_srtp_parameters,
        plain_transport_connect,
        plain_transport_get_stats,
        plain_transport_produce,
        plain_transport_consume,
        plain_transport_close,
        plain_transport_closed,
        plain_transport_event,

        // consumer
        consumer_id,
        consumer_producer_id,
        consumer_kind,
        consumer_type,
        consumer_rtp_parameters,
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

        // data consumer
        data_consumer_id,
        data_consumer_producer_id,
        data_consumer_type,
        data_consumer_sctp_stream_parameters,
        data_consumer_label,
        data_consumer_protocol,
        data_consumer_close,
        data_consumer_closed,
        data_consumer_event,

        // producer
        producer_id,
        producer_kind,
        producer_type,
        producer_rtp_parameters,
        producer_close,
        producer_pause,
        producer_resume,
        producer_closed,
        producer_paused,
        producer_score,
        producer_get_stats,
        producer_event,
        producer_dump,

        // data producer
        data_producer_id,
        data_producer_type,
        data_producer_sctp_stream_parameters,
        data_producer_close,
        data_producer_closed,
        data_producer_event,

        // logger proxy,

        init_env_logger,
        set_logger_proxy_process,
        debug_logger,

    ],
    load = on_load
}

fn on_load<'a>(env: Env<'a>, _load_info: Term<'a>) -> bool {
    // This macro will take care of defining and initializing a new resource
    // object type.
    rustler::resource!(WorkerRef, env);
    rustler::resource!(RouterRef, env);
    rustler::resource!(WebRtcServerRef, env);
    rustler::resource!(WebRtcTransportRef, env);
    rustler::resource!(PipeTransportRef, env);
    rustler::resource!(PlainTransportRef, env);
    rustler::resource!(ConsumerRef, env);
    rustler::resource!(DataConsumerRef, env);
    rustler::resource!(ProducerRef, env);
    rustler::resource!(DataProducerRef, env);
    true
}

pub type WorkerRef = DisposableResourceWrapper<Worker>;
pub type RouterRef = DisposableResourceWrapper<Router>;
pub type WebRtcServerRef = DisposableResourceWrapper<WebRtcServer>;
pub type WebRtcTransportRef = DisposableResourceWrapper<WebRtcTransport>;
pub type PipeTransportRef = DisposableResourceWrapper<PipeTransport>;
pub type PlainTransportRef = DisposableResourceWrapper<PlainTransport>;
pub type ConsumerRef = DisposableResourceWrapper<Consumer>;
pub type DataConsumerRef = DisposableResourceWrapper<DataConsumer>;
pub type ProducerRef = DisposableResourceWrapper<Producer>;
pub type DataProducerRef = DisposableResourceWrapper<DataProducer>;

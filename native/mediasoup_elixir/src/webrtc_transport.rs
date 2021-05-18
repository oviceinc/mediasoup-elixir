use crate::atoms;
use crate::consumer::ConsumerStruct;
use crate::json_serde::{json_encode, JsonDecoder, JsonSerdeWrap};
use crate::producer::ProducerStruct;
use crate::{send_msg_from_other_thread, WebRtcTransportRef};
use futures_lite::future;
use mediasoup::consumer::{ConsumerLayers, ConsumerOptions};
use mediasoup::producer::{ProducerId, ProducerOptions};
use mediasoup::rtp_parameters::{MediaKind, RtpCapabilities, RtpParameters};
use mediasoup::transport::{Transport, TransportGeneric, TransportId};
use mediasoup::webrtc_transport::{WebRtcTransport, WebRtcTransportRemoteParameters};
use rustler::{Encoder, Env, Error, NifStruct, ResourceArc, Term};
use serde::{Deserialize, Serialize};

#[derive(NifStruct)]
#[module = "Mediasoup.WebRtcTransport"]
pub struct WebRtcTransportStruct {
    id: JsonSerdeWrap<TransportId>,
    reference: ResourceArc<WebRtcTransportRef>,
}
impl WebRtcTransportStruct {
    pub fn from(transport: WebRtcTransport) -> Self {
        Self {
            id: transport.id().into(),
            reference: WebRtcTransportRef::resource(transport),
        }
    }
}

pub fn webrtc_transport_id<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let transport: ResourceArc<WebRtcTransportRef> = args[0].decode()?;
    let transport = match transport.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    Ok(transport.id().to_string().encode(env))
}
pub fn webrtc_transport_close<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let transport: ResourceArc<WebRtcTransportRef> = args[0].decode()?;
    transport.close();
    Ok((atoms::ok(),).encode(env))
}
pub fn webrtc_transport_consume<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let transport: ResourceArc<WebRtcTransportRef> = args[0].decode()?;
    let transport = match transport.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };

    let ser_option: SerConsumerOptions = args[1].decode()?;
    let option = ConsumerOptions::from(ser_option);

    let r = match future::block_on(async move {
        return transport.consume(option).await;
    }) {
        Ok(consumer) => (atoms::ok(), ConsumerStruct::from(consumer)).encode(env),
        Err(error) => (atoms::error(), format!("{}", error)).encode(env),
    };
    Ok(r)
}
pub fn webrtc_transport_connect<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let transport: ResourceArc<WebRtcTransportRef> = args[0].decode()?;
    let transport = match transport.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    let option: WebRtcTransportRemoteParameters = JsonDecoder::decode(args[1])?;

    let r = match future::block_on(async move {
        return transport.connect(option).await;
    }) {
        Ok(_) => (atoms::ok(),).encode(env),
        Err(error) => (atoms::error(), format!("{}", error)).encode(env),
    };
    Ok(r)
}
pub fn webrtc_transport_produce<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let transport: ResourceArc<WebRtcTransportRef> = args[0].decode()?;
    let transport = match transport.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    let option: SerProducerOptions = args[1].decode()?;
    let option = ProducerOptions::from(option);

    let r = match future::block_on(async move {
        return transport.produce(option).await;
    }) {
        Ok(producer) => (atoms::ok(), ProducerStruct::from(producer)).encode(env),
        Err(error) => (atoms::error(), format!("{}", error)).encode(env),
    };
    Ok(r)
}

pub fn webrtc_transport_ice_candidates<'a>(
    env: Env<'a>,
    args: &[Term<'a>],
) -> Result<Term<'a>, Error> {
    let transport: ResourceArc<WebRtcTransportRef> = args[0].decode()?;
    let transport = match transport.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    return Ok(json_encode(transport.ice_candidates(), env));
}
pub fn webrtc_transport_ice_role<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let transport: ResourceArc<WebRtcTransportRef> = args[0].decode()?;
    let transport = match transport.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    return Ok(json_encode(&transport.ice_role(), env));
}

pub fn webrtc_transport_set_max_incoming_bitrate<'a>(
    env: Env<'a>,
    args: &[Term<'a>],
) -> Result<Term<'a>, Error> {
    let transport: ResourceArc<WebRtcTransportRef> = args[0].decode()?;
    let transport = match transport.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    let bitrate: u32 = args[1].decode()?;

    let r = match future::block_on(async move {
        return transport.set_max_incoming_bitrate(bitrate).await;
    }) {
        Ok(_) => (atoms::ok(),).encode(env),
        Err(error) => (atoms::error(), format!("{}", error)).encode(env),
    };
    Ok(r)
}

pub fn webrtc_transport_ice_state<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let transport: ResourceArc<WebRtcTransportRef> = args[0].decode()?;
    let transport = match transport.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    return Ok(json_encode(&transport.ice_state(), env));
}
pub fn webrtc_transport_restart_ice<'a>(
    env: Env<'a>,
    args: &[Term<'a>],
) -> Result<Term<'a>, Error> {
    let transport: ResourceArc<WebRtcTransportRef> = args[0].decode()?;
    let transport = match transport.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };

    let r = match future::block_on(async move {
        return transport.restart_ice().await;
    }) {
        Ok(ice_parameter) => (atoms::ok(), json_encode(&ice_parameter, env)).encode(env),
        Err(error) => (atoms::error(), format!("{}", error)).encode(env),
    };
    Ok(r)
}

pub fn webrtc_transport_get_stats<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let transport: ResourceArc<WebRtcTransportRef> = args[0].decode()?;
    let transport = match transport.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };

    let status = future::block_on(async move {
        return transport.get_stats().await;
    })
    .map_err(|e| Error::RaiseTerm(Box::new(format!("{}", e))))?;

    Ok(json_encode(&status, env))
}

pub fn webrtc_transport_dump<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let transport: ResourceArc<WebRtcTransportRef> = args[0].decode()?;
    let transport = match transport.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };

    let r = match future::block_on(async move {
        return transport.dump().await;
    }) {
        Ok(dump) => json_encode(&dump, env),
        Err(error) => (atoms::error(), format!("{}", error)).encode(env),
    };
    return Ok(r);
}
pub fn webrtc_transport_ice_selected_tuple<'a>(
    env: Env<'a>,
    args: &[Term<'a>],
) -> Result<Term<'a>, Error> {
    let transport: ResourceArc<WebRtcTransportRef> = args[0].decode()?;
    let transport = match transport.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    return Ok(json_encode(&transport.ice_selected_tuple(), env));
}
pub fn webrtc_transport_dtls_parameters<'a>(
    env: Env<'a>,
    args: &[Term<'a>],
) -> Result<Term<'a>, Error> {
    let transport: ResourceArc<WebRtcTransportRef> = args[0].decode()?;
    let transport = match transport.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    return Ok(json_encode(&transport.dtls_parameters(), env));
}

pub fn webrtc_transport_dtls_state<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let transport: ResourceArc<WebRtcTransportRef> = args[0].decode()?;
    let transport = match transport.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    return Ok(json_encode(&transport.dtls_state(), env));
}
pub fn webrtc_transport_sctp_state<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let transport: ResourceArc<WebRtcTransportRef> = args[0].decode()?;
    let transport = match transport.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    return Ok(json_encode(&transport.sctp_state(), env));
}

pub fn webrtc_transport_event<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let transport: ResourceArc<WebRtcTransportRef> = args[0].decode()?;
    let transport = match transport.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    let pid: rustler::Pid = args[1].decode()?;

    //    crate::reg_callback!(env, transport, on_close);

    crate::reg_callback_json_param!(pid, transport, on_sctp_state_change);
    crate::reg_callback_json_param!(pid, transport, on_ice_state_change);
    crate::reg_callback_json_param!(pid, transport, on_dtls_state_change);

    /* TODO: Can not create multiple instance for disposable
    {
        let pid = pid.clone();
        transport
            .on_new_producer(Box::new(move |producer| {
                send_msg_from_other_thread(
                    pid.clone(),
                    (
                        atoms::on_new_producer(),
                        ProducerStruct::from(producer.clone()),
                    ),
                );
            }))
            .detach();
    }

    {
        let pid = pid.clone();
        transport
            .on_new_consumer(Box::new(move |consumer| {
                send_msg_from_other_thread(
                    pid.clone(),
                    (
                        atoms::on_new_consumer(),
                        ConsumerStruct::from(consumer.clone()),
                    ),
                );
            }))
            .detach();
    }
    */

    {
        let pid = pid.clone();
        transport
            .on_ice_selected_tuple_change(move |arg| {
                send_msg_from_other_thread(
                    pid.clone(),
                    (
                        atoms::on_ice_selected_tuple_change(),
                        JsonSerdeWrap::new(arg.clone()),
                    ),
                );
            })
            .detach();
    }

    Ok((atoms::ok(),).encode(env))
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct SerConsumerOptions {
    producer_id: ProducerId,
    rtp_capabilities: RtpCapabilities,
    paused: Option<bool>,
    preferred_layers: Option<ConsumerLayers>,
    pipe: Option<bool>,
}
crate::define_rustler_serde_by_json!(SerConsumerOptions);

impl From<SerConsumerOptions> for ConsumerOptions {
    fn from(v: SerConsumerOptions) -> ConsumerOptions {
        let mut option = ConsumerOptions::new(v.producer_id, v.rtp_capabilities);
        if let Some(paused) = v.paused {
            option.paused = paused;
        }
        option.preferred_layers = v.preferred_layers;
        if let Some(pipe) = v.pipe {
            option.pipe = pipe;
        }
        option
    }
}

#[derive(Serialize, Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
struct SerProducerOptions {
    pub id: Option<ProducerId>,
    pub kind: MediaKind,
    pub rtp_parameters: RtpParameters,
    pub paused: Option<bool>,
    pub key_frame_request_delay: Option<u32>,
}

crate::define_rustler_serde_by_json!(SerProducerOptions);

impl From<SerProducerOptions> for ProducerOptions {
    fn from(v: SerProducerOptions) -> ProducerOptions {
        let mut option = match v.id {
            Some(id) => ProducerOptions::new_pipe_transport(id, v.kind, v.rtp_parameters),
            None => ProducerOptions::new(v.kind, v.rtp_parameters),
        };

        option.paused = v.paused.unwrap_or(option.paused);
        option.key_frame_request_delay = v
            .key_frame_request_delay
            .unwrap_or(option.key_frame_request_delay);
        option
    }
}

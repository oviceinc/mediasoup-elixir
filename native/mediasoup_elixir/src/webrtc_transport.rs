use crate::atoms;
use crate::consumer::ConsumerStruct;
use crate::json_serde::JsonSerdeWrap;
use crate::producer::ProducerStruct;
use crate::{send_msg_from_other_thread, WebRtcTransportRef};
use futures_lite::future;
use mediasoup::consumer::{ConsumerLayers, ConsumerOptions};
use mediasoup::data_structures::{
    DtlsParameters, DtlsState, IceParameters, IceRole, IceState, SctpState, TransportTuple,
};
use mediasoup::producer::{ProducerId, ProducerOptions};
use mediasoup::rtp_parameters::{MediaKind, RtpCapabilities, RtpParameters};
use mediasoup::transport::{Transport, TransportGeneric, TransportId};
use mediasoup::webrtc_transport::{
    WebRtcTransport, WebRtcTransportDump, WebRtcTransportRemoteParameters, WebRtcTransportStat,
};
use rustler::{Atom, Env, Error, NifResult, NifStruct, ResourceArc, Term};
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

#[rustler::nif]
pub fn webrtc_transport_id(transport: ResourceArc<WebRtcTransportRef>) -> NifResult<String> {
    let transport = transport
        .unwrap()
        .ok_or(Error::Term(Box::new(atoms::terminated())))?;
    Ok(transport.id().to_string())
}

#[rustler::nif]
pub fn webrtc_transport_close(transport: ResourceArc<WebRtcTransportRef>) -> NifResult<(Atom,)> {
    transport.close();
    Ok((atoms::ok(),))
}

#[rustler::nif]
pub fn webrtc_transport_consume(
    transport: ResourceArc<WebRtcTransportRef>,
    ser_option: SerConsumerOptions,
) -> NifResult<(Atom, ConsumerStruct)> {
    let transport = transport
        .unwrap()
        .ok_or(Error::Term(Box::new(atoms::terminated())))?;

    let option = ConsumerOptions::from(ser_option);

    let r = future::block_on(async move {
        return transport.consume(option).await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;

    Ok((atoms::ok(), ConsumerStruct::from(r)))
}

#[rustler::nif]
pub fn webrtc_transport_connect(
    transport: ResourceArc<WebRtcTransportRef>,
    option: JsonSerdeWrap<WebRtcTransportRemoteParameters>,
) -> NifResult<(Atom,)> {
    let transport = transport
        .unwrap()
        .ok_or(Error::Term(Box::new(atoms::terminated())))?;
    let option: WebRtcTransportRemoteParameters = option.clone();

    future::block_on(async move {
        return transport.connect(option).await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;
    Ok((atoms::ok(),))
}

#[rustler::nif]
pub fn webrtc_transport_produce(
    transport: ResourceArc<WebRtcTransportRef>,
    option: SerProducerOptions,
) -> NifResult<(Atom, ProducerStruct)> {
    let transport = transport
        .unwrap()
        .ok_or(Error::Term(Box::new(atoms::terminated())))?;
    let option = ProducerOptions::from(option);

    let producer = future::block_on(async move {
        return transport.produce(option).await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;
    Ok((atoms::ok(), ProducerStruct::from(producer)))
}

#[rustler::nif]
pub fn webrtc_transport_ice_candidates(
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<JsonSerdeWrap<std::vec::Vec<mediasoup::data_structures::IceCandidate>>> {
    let transport = transport
        .unwrap()
        .ok_or(Error::Term(Box::new(atoms::terminated())))?;
    Ok(JsonSerdeWrap::new(transport.ice_candidates().clone()))
}

#[rustler::nif]
pub fn webrtc_transport_ice_role(
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<JsonSerdeWrap<IceRole>> {
    let transport = transport
        .unwrap()
        .ok_or(Error::Term(Box::new(atoms::terminated())))?;
    Ok(JsonSerdeWrap::new(transport.ice_role()))
}

#[rustler::nif]
pub fn webrtc_transport_set_max_incoming_bitrate(
    transport: ResourceArc<WebRtcTransportRef>,
    bitrate: u32,
) -> NifResult<(Atom,)> {
    let transport = transport
        .unwrap()
        .ok_or(Error::Term(Box::new(atoms::terminated())))?;

    future::block_on(async move {
        return transport.set_max_incoming_bitrate(bitrate).await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;
    Ok((atoms::ok(),))
}

#[rustler::nif]
pub fn webrtc_transport_ice_state(
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<JsonSerdeWrap<IceState>> {
    let transport = transport
        .unwrap()
        .ok_or(Error::Term(Box::new(atoms::terminated())))?;
    Ok(JsonSerdeWrap::new(transport.ice_state()))
}

#[rustler::nif]
pub fn webrtc_transport_restart_ice(
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<(Atom, JsonSerdeWrap<IceParameters>)> {
    let transport = transport
        .unwrap()
        .ok_or(Error::Term(Box::new(atoms::terminated())))?;

    let ice_parameter = future::block_on(async move {
        return transport.restart_ice().await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;

    Ok((atoms::ok(), JsonSerdeWrap::new(ice_parameter)))
}

#[rustler::nif]
pub fn webrtc_transport_get_stats(
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<JsonSerdeWrap<std::vec::Vec<WebRtcTransportStat>>> {
    let transport = transport
        .unwrap()
        .ok_or(Error::Term(Box::new(atoms::terminated())))?;

    let status = future::block_on(async move {
        return transport.get_stats().await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;

    Ok(JsonSerdeWrap::new(status))
}

#[rustler::nif]
pub fn webrtc_transport_dump(
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<JsonSerdeWrap<WebRtcTransportDump>> {
    let transport = transport
        .unwrap()
        .ok_or(Error::Term(Box::new(atoms::terminated())))?;

    let dump = future::block_on(async move {
        return transport.dump().await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;

    Ok(JsonSerdeWrap::new(dump))
}

#[rustler::nif]
pub fn webrtc_transport_ice_selected_tuple(
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<JsonSerdeWrap<Option<TransportTuple>>> {
    let transport = transport
        .unwrap()
        .ok_or(Error::Term(Box::new(atoms::terminated())))?;
    Ok(JsonSerdeWrap::new(transport.ice_selected_tuple()))
}

#[rustler::nif]
pub fn webrtc_transport_dtls_parameters(
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<JsonSerdeWrap<DtlsParameters>> {
    let transport = transport
        .unwrap()
        .ok_or(Error::Term(Box::new(atoms::terminated())))?;
    Ok(JsonSerdeWrap::new(transport.dtls_parameters()))
}

#[rustler::nif]
pub fn webrtc_transport_dtls_state(
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<JsonSerdeWrap<DtlsState>> {
    let transport = transport
        .unwrap()
        .ok_or(Error::Term(Box::new(atoms::terminated())))?;
    Ok(JsonSerdeWrap::new(transport.dtls_state()))
}
#[rustler::nif]
pub fn webrtc_transport_sctp_state(
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<JsonSerdeWrap<Option<SctpState>>> {
    let transport = transport
        .unwrap()
        .ok_or(Error::Term(Box::new(atoms::terminated())))?;
    Ok(JsonSerdeWrap::new(transport.sctp_state()))
}

#[rustler::nif]
pub fn webrtc_transport_event(
    transport: ResourceArc<WebRtcTransportRef>,
    pid: rustler::LocalPid,
) -> NifResult<(Atom,)> {
    let transport = transport
        .unwrap()
        .ok_or(Error::Term(Box::new(atoms::terminated())))?;

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

    Ok((atoms::ok(),))
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SerConsumerOptions {
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
pub struct SerProducerOptions {
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

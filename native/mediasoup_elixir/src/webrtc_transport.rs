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
use mediasoup::sctp_parameters::SctpParameters;
use mediasoup::transport::{Transport, TransportGeneric, TransportId};
use mediasoup::webrtc_transport::{
    WebRtcTransport, WebRtcTransportDump, WebRtcTransportRemoteParameters, WebRtcTransportStat,
};
use rustler::{Atom, Error, NifResult, NifStruct, ResourceArc};
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
    let transport = transport.get_resource()?;
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
    ser_option: JsonSerdeWrap<SerConsumerOptions>,
) -> NifResult<(Atom, ConsumerStruct)> {
    let transport = transport.get_resource()?;

    let option: ConsumerOptions = ser_option.to_option();

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
    let transport = transport.get_resource()?;
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
    option: JsonSerdeWrap<SerProducerOptions>,
) -> NifResult<(Atom, ProducerStruct)> {
    let transport = transport.get_resource()?;
    let option: ProducerOptions = option.to_option();

    let producer = future::block_on(async move {
        return transport.produce(option).await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;
    Ok((atoms::ok(), ProducerStruct::from(producer)))
}

#[rustler::nif]
pub fn webrtc_transport_ice_parameters(
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<JsonSerdeWrap<IceParameters>> {
    let transport = transport.get_resource()?;
    Ok(JsonSerdeWrap::new(transport.ice_parameters().clone()))
}

#[rustler::nif]
pub fn webrtc_transport_sctp_parameters(
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<JsonSerdeWrap<Option<SctpParameters>>> {
    let transport = transport.get_resource()?;
    Ok(JsonSerdeWrap::new(transport.sctp_parameters()))
}

#[rustler::nif]
pub fn webrtc_transport_ice_candidates(
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<JsonSerdeWrap<std::vec::Vec<mediasoup::data_structures::IceCandidate>>> {
    let transport = transport.get_resource()?;
    Ok(JsonSerdeWrap::new(transport.ice_candidates().clone()))
}

#[rustler::nif]
pub fn webrtc_transport_ice_role(
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<JsonSerdeWrap<IceRole>> {
    let transport = transport.get_resource()?;
    Ok(JsonSerdeWrap::new(transport.ice_role()))
}

#[rustler::nif]
pub fn webrtc_transport_set_max_incoming_bitrate(
    transport: ResourceArc<WebRtcTransportRef>,
    bitrate: u32,
) -> NifResult<(Atom,)> {
    let transport = transport.get_resource()?;

    future::block_on(async move {
        return transport.set_max_incoming_bitrate(bitrate).await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;
    Ok((atoms::ok(),))
}

#[rustler::nif]
pub fn webrtc_transport_set_max_outgoing_bitrate(
    transport: ResourceArc<WebRtcTransportRef>,
    bitrate: u32,
) -> NifResult<(Atom,)> {
    let transport = transport.get_resource()?;

    future::block_on(async move {
        return transport.set_max_outgoing_bitrate(bitrate).await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;
    Ok((atoms::ok(),))
}

#[rustler::nif]
pub fn webrtc_transport_ice_state(
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<JsonSerdeWrap<IceState>> {
    let transport = transport.get_resource()?;
    Ok(JsonSerdeWrap::new(transport.ice_state()))
}

#[rustler::nif]
pub fn webrtc_transport_restart_ice(
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<(Atom, JsonSerdeWrap<IceParameters>)> {
    let transport = transport.get_resource()?;

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
    let transport = transport.get_resource()?;

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
    let transport = transport.get_resource()?;

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
    let transport = transport.get_resource()?;
    Ok(JsonSerdeWrap::new(transport.ice_selected_tuple()))
}

#[rustler::nif]
pub fn webrtc_transport_dtls_parameters(
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<JsonSerdeWrap<DtlsParameters>> {
    let transport = transport.get_resource()?;
    Ok(JsonSerdeWrap::new(transport.dtls_parameters()))
}

#[rustler::nif]
pub fn webrtc_transport_dtls_state(
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<JsonSerdeWrap<DtlsState>> {
    let transport = transport.get_resource()?;
    Ok(JsonSerdeWrap::new(transport.dtls_state()))
}
#[rustler::nif]
pub fn webrtc_transport_sctp_state(
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<JsonSerdeWrap<Option<SctpState>>> {
    let transport = transport.get_resource()?;
    Ok(JsonSerdeWrap::new(transport.sctp_state()))
}

#[rustler::nif]
pub fn webrtc_transport_event(
    transport: ResourceArc<WebRtcTransportRef>,
    pid: rustler::LocalPid,
) -> NifResult<(Atom,)> {
    let transport = transport.get_resource()?;

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
        //        let pid = pid.clone();
        transport
            .on_ice_selected_tuple_change(move |arg| {
                send_msg_from_other_thread(
                    pid.clone(),
                    (
                        atoms::on_ice_selected_tuple_change(),
                        JsonSerdeWrap::new(*arg),
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

impl SerConsumerOptions {
    fn to_option(&self) -> ConsumerOptions {
        let mut option = ConsumerOptions::new(self.producer_id, self.rtp_capabilities.clone());
        if let Some(paused) = self.paused {
            option.paused = paused;
        }
        option.preferred_layers = self.preferred_layers;
        if let Some(pipe) = self.pipe {
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

impl SerProducerOptions {
    fn to_option(&self) -> ProducerOptions {
        let mut option = match self.id {
            Some(id) => {
                ProducerOptions::new_pipe_transport(id, self.kind, self.rtp_parameters.clone())
            }
            None => ProducerOptions::new(self.kind, self.rtp_parameters.clone()),
        };

        option.paused = self.paused.unwrap_or(option.paused);
        option.key_frame_request_delay = self
            .key_frame_request_delay
            .unwrap_or(option.key_frame_request_delay);

        option
    }
}

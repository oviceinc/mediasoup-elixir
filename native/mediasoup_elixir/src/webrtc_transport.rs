use crate::atoms;
use crate::consumer::{ConsumerOptionsStruct, ConsumerStruct};
use crate::data_structure::SerNumSctpStreams;
use crate::json_serde::JsonSerdeWrap;
use crate::producer::{ProducerOptionsStruct, ProducerStruct};
use crate::{send_msg_from_other_thread, WebRtcTransportRef};
use futures_lite::future;
use mediasoup::consumer::ConsumerOptions;
use mediasoup::data_structures::{
    DtlsParameters, DtlsState, IceParameters, IceRole, IceState, SctpState, TransportListenIp,
    TransportTuple,
};
use mediasoup::producer::ProducerOptions;
use mediasoup::sctp_parameters::SctpParameters;
use mediasoup::transport::{Transport, TransportGeneric, TransportId};
use mediasoup::webrtc_transport::{
    TransportListenIps, WebRtcTransport, WebRtcTransportDump, WebRtcTransportOptions,
    WebRtcTransportRemoteParameters, WebRtcTransportStat,
};
use rustler::{Atom, Error, NifResult, NifStruct, ResourceArc};

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
    option: ConsumerOptionsStruct,
) -> NifResult<(Atom, ConsumerStruct)> {
    let transport = transport.get_resource()?;

    let option: ConsumerOptions = option.to_option();

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
    option: ProducerOptionsStruct,
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

#[derive(NifStruct)]
#[module = "Mediasoup.WebRtcTransport.Options"]
pub struct WebRtcTransportOptionsStruct {
    listen_ips: JsonSerdeWrap<Vec<TransportListenIp>>,
    enable_udp: Option<bool>,
    enable_tcp: Option<bool>,
    prefer_udp: Option<bool>,
    prefer_tcp: Option<bool>,
    initial_available_outgoing_bitrate: Option<u32>,
    enable_sctp: Option<bool>,
    num_sctp_streams: Option<JsonSerdeWrap<SerNumSctpStreams>>,
    max_sctp_message_size: Option<u32>,
    sctp_send_buffer_size: Option<u32>,
}
impl WebRtcTransportOptionsStruct {
    pub fn try_to_option(&self) -> Result<WebRtcTransportOptions, &'static str> {
        let ips = match self.listen_ips.first() {
            None => Err("Rquired least one ip"),
            Some(ip) => Ok(TransportListenIps::new(*ip)),
        }?;

        let ips = self.listen_ips[1..]
            .iter()
            .fold(ips, |ips, ip| ips.insert(*ip));

        let mut option = WebRtcTransportOptions::new(ips);
        if let Some(enable_udp) = self.enable_udp {
            option.enable_udp = enable_udp;
        }
        if let Some(enable_tcp) = self.enable_tcp {
            option.enable_tcp = enable_tcp;
        }
        if let Some(prefer_udp) = self.prefer_udp {
            option.prefer_udp = prefer_udp;
        }
        if let Some(prefer_tcp) = self.prefer_tcp {
            option.prefer_tcp = prefer_tcp;
        }
        if let Some(initial_available_outgoing_bitrate) = self.initial_available_outgoing_bitrate {
            option.initial_available_outgoing_bitrate = initial_available_outgoing_bitrate;
        }
        if let Some(enable_sctp) = self.enable_sctp {
            option.enable_sctp = enable_sctp;
        }
        if let Some(num_sctp_streams) = &self.num_sctp_streams {
            option.num_sctp_streams = num_sctp_streams.as_streams();
        }
        if let Some(max_sctp_message_size) = self.max_sctp_message_size {
            option.max_sctp_message_size = max_sctp_message_size;
        }
        if let Some(sctp_send_buffer_size) = self.sctp_send_buffer_size {
            option.sctp_send_buffer_size = sctp_send_buffer_size;
        }
        Ok(option)
    }
}

use crate::consumer::{ConsumerOptionsStruct, ConsumerRef};
use crate::data_consumer::{DataConsumerOptionsStruct, DataConsumerRef};
use crate::data_producer::{DataProducerOptionsStruct, DataProducerRef};
use crate::data_structure::SerNumSctpStreams;
use crate::json_serde::JsonSerdeWrap;
use crate::producer::{ProducerOptionsStruct, ProducerRef};
use crate::webrtc_server::WebRtcServerRef;
use crate::{atoms, send_async_nif_result, send_msg_from_other_thread, DisposableResourceWrapper};
use mediasoup::data_structures::{
    DtlsParameters, DtlsState, IceParameters, IceRole, IceState, ListenInfo, SctpState,
    TransportTuple,
};
use mediasoup::prelude::{
    ConsumerOptions, DataConsumerOptions, DataProducerOptions, Transport, TransportGeneric,
    WebRtcTransport,
};
use mediasoup::producer::ProducerOptions;
use mediasoup::sctp_parameters::SctpParameters;
use mediasoup::transport::TransportId;
use mediasoup::webrtc_transport::{
    WebRtcTransportListenInfos, WebRtcTransportOptions, WebRtcTransportRemoteParameters,
};
use rustler::{Atom, Env, NifResult, NifStruct, ResourceArc};

pub type WebRtcTransportRef = DisposableResourceWrapper<WebRtcTransport>;

#[rustler::resource_impl]
impl rustler::Resource for WebRtcTransportRef {}

#[rustler::nif]
pub fn webrtc_transport_id(
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<JsonSerdeWrap<TransportId>> {
    let transport = transport.get_resource()?;
    Ok(transport.id().into())
}

#[rustler::nif]
pub fn webrtc_transport_close(transport: ResourceArc<WebRtcTransportRef>) -> NifResult<(Atom,)> {
    transport.close();
    Ok((atoms::ok(),))
}

#[rustler::nif]
pub fn webrtc_transport_closed(transport: ResourceArc<WebRtcTransportRef>) -> NifResult<bool> {
    match transport.get_resource() {
        Ok(transport) => Ok(transport.closed()),
        Err(_) => Ok(true),
    }
}

#[rustler::nif(name = "webrtc_transport_consume_async")]
pub fn webrtc_transport_consume(
    env: Env,
    transport: ResourceArc<WebRtcTransportRef>,
    option: ConsumerOptionsStruct,
) -> NifResult<(Atom, Atom)> {
    let transport = transport.get_resource()?;

    let option: ConsumerOptions = option.to_option();

    send_async_nif_result(env, async move {
        transport
            .consume(option)
            .await
            .map(ConsumerRef::new)
            .map(ResourceArc::new)
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif(name = "webrtc_transport_consume_data_async")]
pub fn webrtc_transport_consume_data(
    env: Env,
    transport: ResourceArc<WebRtcTransportRef>,
    option: DataConsumerOptionsStruct,
) -> NifResult<(Atom, Atom)> {
    let transport = transport.get_resource()?;

    let option: DataConsumerOptions = option.to_option();

    send_async_nif_result(env, async move {
        transport
            .consume_data(option)
            .await
            .map(DataConsumerRef::new)
            .map(ResourceArc::new)
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif(name = "webrtc_transport_connect_async")]
pub fn webrtc_transport_connect(
    env: Env,
    transport: ResourceArc<WebRtcTransportRef>,
    option: JsonSerdeWrap<WebRtcTransportRemoteParameters>,
) -> NifResult<(Atom, Atom)> {
    let transport = transport.get_resource()?;
    let option: WebRtcTransportRemoteParameters = option.clone();

    send_async_nif_result(env, async move {
        transport
            .connect(option)
            .await
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif(name = "webrtc_transport_produce_async")]
pub fn webrtc_transport_produce(
    env: Env,
    transport: ResourceArc<WebRtcTransportRef>,
    option: ProducerOptionsStruct,
) -> NifResult<(Atom, Atom)> {
    let transport = transport.get_resource()?;
    let option: ProducerOptions = option.to_option();

    send_async_nif_result(env, async move {
        transport
            .produce(option)
            .await
            .map(ProducerRef::new)
            .map(ResourceArc::new)
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif(name = "webrtc_transport_produce_data_async")]
pub fn webrtc_transport_produce_data(
    env: Env,
    transport: ResourceArc<WebRtcTransportRef>,
    option: DataProducerOptionsStruct,
) -> NifResult<(Atom, Atom)> {
    let transport = transport.get_resource()?;
    let option: DataProducerOptions = option.to_option();

    send_async_nif_result(env, async move {
        transport
            .produce_data(option)
            .await
            .map(DataProducerRef::new)
            .map(ResourceArc::new)
            .map_err(|error| format!("{}", error))
    })
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

#[rustler::nif(name = "webrtc_transport_set_max_incoming_bitrate_async")]
pub fn webrtc_transport_set_max_incoming_bitrate(
    env: Env,
    transport: ResourceArc<WebRtcTransportRef>,
    bitrate: u32,
) -> NifResult<(Atom, Atom)> {
    let transport = transport.get_resource()?;

    send_async_nif_result(env, async move {
        transport
            .set_max_incoming_bitrate(bitrate)
            .await
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif(name = "webrtc_transport_set_max_outgoing_bitrate_async")]
pub fn webrtc_transport_set_max_outgoing_bitrate(
    env: Env,
    transport: ResourceArc<WebRtcTransportRef>,
    bitrate: u32,
) -> NifResult<(Atom, Atom)> {
    let transport = transport.get_resource()?;

    send_async_nif_result(env, async move {
        transport
            .set_max_outgoing_bitrate(bitrate)
            .await
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif]
pub fn webrtc_transport_ice_state(
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<JsonSerdeWrap<IceState>> {
    let transport = transport.get_resource()?;
    Ok(JsonSerdeWrap::new(transport.ice_state()))
}

#[rustler::nif(name = "webrtc_transport_restart_ice_async")]
pub fn webrtc_transport_restart_ice(
    env: Env,
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<(Atom, Atom)> {
    let transport = transport.get_resource()?;

    send_async_nif_result(env, async move {
        transport
            .restart_ice()
            .await
            .map(JsonSerdeWrap::new)
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif(name = "webrtc_transport_get_stats_async")]
pub fn webrtc_transport_get_stats(
    env: Env,
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<(Atom, Atom)> {
    let transport = transport.get_resource()?;

    send_async_nif_result(env, async move {
        transport
            .get_stats()
            .await
            .map(JsonSerdeWrap::new)
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif(name = "webrtc_transport_dump_async")]
pub fn webrtc_transport_dump(
    env: Env,
    transport: ResourceArc<WebRtcTransportRef>,
) -> NifResult<(Atom, Atom)> {
    let transport = transport.get_resource()?;

    send_async_nif_result(env, async move {
        transport
            .dump()
            .await
            .map(JsonSerdeWrap::new)
            .map_err(|error| format!("{}", error))
    })
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
    event_types: Vec<Atom>,
) -> NifResult<(Atom,)> {
    let transport = transport.get_resource()?;

    if event_types.contains(&atoms::on_close()) {
        crate::reg_callback_once!(pid, transport, on_close);
    }

    if event_types.contains(&atoms::on_sctp_state_change()) {
        crate::reg_callback_json_param!(pid, transport, on_sctp_state_change);
    }
    if event_types.contains(&atoms::on_ice_state_change()) {
        crate::reg_callback_json_param!(pid, transport, on_ice_state_change);
    }
    if event_types.contains(&atoms::on_dtls_state_change()) {
        crate::reg_callback_json_param!(pid, transport, on_dtls_state_change);
    }

    if event_types.contains(&atoms::on_ice_selected_tuple_change()) {
        transport
            .on_ice_selected_tuple_change(move |arg| {
                send_msg_from_other_thread(
                    pid,
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

#[derive(NifStruct)]
#[module = "Mediasoup.WebRtcTransport.Options"]
pub struct WebRtcTransportOptionsStruct {
    listen_infos: Option<JsonSerdeWrap<Vec<ListenInfo>>>,
    webrtc_server: Option<ResourceArc<WebRtcServerRef>>,
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
    pub fn try_to_option(&self) -> NifResult<WebRtcTransportOptions> {
        let mut option = if let Some(webrtc_server) = &self.webrtc_server {
            let webrtc_server = webrtc_server.get_resource()?;
            Ok(WebRtcTransportOptions::new_with_server(webrtc_server))
        } else if let Some(listen_infos) = &self.listen_infos {
            let infos = match listen_infos.first() {
                None => Err(rustler::Error::Term(Box::new("Rquired least one ip"))),
                Some(ip) => Ok(WebRtcTransportListenInfos::new(ip.clone())),
            }?;

            let infos = listen_infos[1..]
                .iter()
                .fold(infos, |infos, ip| infos.insert(ip.clone()));

            Ok(WebRtcTransportOptions::new(infos))
        } else {
            Err(rustler::Error::Term(Box::new(
                "Rquired least one ip or webrtc_server",
            )))
        }?;

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

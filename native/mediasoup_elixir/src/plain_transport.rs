use crate::consumer::ConsumerOptionsStruct;
use crate::data_structure::SerNumSctpStreams;
use crate::json_serde::JsonSerdeWrap;
use crate::PlainTransportRef;
use crate::{atoms, send_async_nif_result, ConsumerRef};
use mediasoup::consumer::ConsumerOptions;
use mediasoup::data_structures::{ListenIp, SctpState, TransportTuple};
use mediasoup::plain_transport::{PlainTransportOptions, PlainTransportRemoteParameters};
use mediasoup::prelude::Transport;
use mediasoup::sctp_parameters::SctpParameters;
use mediasoup::srtp_parameters::SrtpParameters;
use mediasoup::transport::{TransportGeneric, TransportId};
use rustler::{Atom, Env, NifResult, NifStruct, ResourceArc};

#[derive(NifStruct)]
#[module = "Mediasoup.PlainTransport.Options"]
pub struct PlainTransportOptionsStruct {
    pub listen_ip: JsonSerdeWrap<ListenIp>,
    pub port: Option<u16>,
    pub rtcp_mux: Option<bool>,
    pub comedia: Option<bool>,
    pub enable_sctp: Option<bool>,
    num_sctp_streams: Option<JsonSerdeWrap<SerNumSctpStreams>>,
    pub max_sctp_message_size: Option<u32>,
    pub sctp_send_buffer_size: Option<u32>,
    pub enable_srtp: Option<bool>,
}
impl PlainTransportOptionsStruct {
    pub fn try_to_option(&self) -> Result<PlainTransportOptions, &'static str> {
        let mut option = PlainTransportOptions::new(*self.listen_ip);

        option.port = self.port;

        if let Some(rtcp_mux) = self.rtcp_mux {
            option.rtcp_mux = rtcp_mux;
        }
        if let Some(comedia) = self.comedia {
            option.comedia = comedia;
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
        if let Some(enable_srtp) = self.enable_srtp {
            option.enable_srtp = enable_srtp;
        }

        Ok(option)
    }
}

#[rustler::nif]
pub fn plain_transport_id(
    transport: ResourceArc<PlainTransportRef>,
) -> NifResult<JsonSerdeWrap<TransportId>> {
    let transport = transport.get_resource()?;
    Ok(transport.id().into())
}

#[rustler::nif]
pub fn plain_transport_tuple(
    transport: ResourceArc<PlainTransportRef>,
) -> NifResult<JsonSerdeWrap<TransportTuple>> {
    let transport = transport.get_resource()?;
    Ok(JsonSerdeWrap::new(transport.tuple()))
}

#[rustler::nif]
pub fn plain_transport_sctp_parameters(
    transport: ResourceArc<PlainTransportRef>,
) -> NifResult<JsonSerdeWrap<Option<SctpParameters>>> {
    let transport = transport.get_resource()?;
    Ok(JsonSerdeWrap::new(transport.sctp_parameters()))
}

#[rustler::nif]
pub fn plain_transport_sctp_state(
    transport: ResourceArc<PlainTransportRef>,
) -> NifResult<JsonSerdeWrap<Option<SctpState>>> {
    let transport = transport.get_resource()?;
    Ok(JsonSerdeWrap::new(transport.sctp_state()))
}

#[rustler::nif]
pub fn plain_transport_srtp_parameters(
    transport: ResourceArc<PlainTransportRef>,
) -> NifResult<JsonSerdeWrap<Option<SrtpParameters>>> {
    let transport = transport.get_resource()?;
    Ok(JsonSerdeWrap::new(transport.srtp_parameters()))
}

#[rustler::nif(name = "plain_transport_connect_async")]
pub fn plain_transport_connect(
    env: Env,
    transport: ResourceArc<PlainTransportRef>,
    option: JsonSerdeWrap<PlainTransportRemoteParameters>,
) -> NifResult<(Atom, Atom)> {
    let transport = transport.get_resource()?;
    let option: PlainTransportRemoteParameters = option.clone();

    send_async_nif_result(env, async move {
        transport
            .connect(option)
            .await
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif(name = "plain_transport_get_stats_async")]
pub fn plain_transport_get_stats(
    env: Env,
    transport: ResourceArc<PlainTransportRef>,
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

#[rustler::nif(name = "plain_transport_consume_async")]
pub fn plain_transport_consume(
    env: Env,
    transport: ResourceArc<PlainTransportRef>,
    option: ConsumerOptionsStruct,
) -> NifResult<(Atom, Atom)> {
    let transport = transport.get_resource()?;

    let option: ConsumerOptions = option.to_option();

    send_async_nif_result(env, async move {
        transport
            .consume(option)
            .await
            .map(ConsumerRef::resource)
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif]
pub fn plain_transport_close(transport: ResourceArc<PlainTransportRef>) -> NifResult<(Atom,)> {
    transport.close();
    Ok((atoms::ok(),))
}

#[rustler::nif]
pub fn plain_transport_closed(transport: ResourceArc<PlainTransportRef>) -> NifResult<bool> {
    match transport.get_resource() {
        Ok(transport) => Ok(transport.closed()),
        Err(_) => Ok(true),
    }
}

#[rustler::nif]
pub fn plain_transport_event(
    transport: ResourceArc<PlainTransportRef>,
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
    if event_types.contains(&atoms::on_tuple()) {
        crate::reg_callback_json_clone_param!(pid, transport, on_tuple);
    }

    Ok((atoms::ok(),))
}

use crate::consumer::{ConsumerOptionsStruct, ConsumerRef};
use crate::json_serde::JsonSerdeWrap;
use crate::producer::{ProducerOptionsStruct, ProducerRef};
use crate::{atoms, send_async_nif_result_with_from, DisposableResourceWrapper};
use mediasoup::consumer::ConsumerOptions;
use mediasoup::prelude::{
    ListenInfo, PlainTransport, PlainTransportOptions, PlainTransportRemoteParameters, Transport,
    TransportGeneric, TransportId,
};
use mediasoup::producer::ProducerOptions;
use mediasoup::types::data_structures::{SctpState, TransportTuple};
use mediasoup::types::sctp_parameters::SctpParameters;
use mediasoup::types::srtp_parameters::SrtpParameters;
use rustler::{Atom, Env, NifResult, NifStruct, ResourceArc, Term};

pub type PlainTransportRef = DisposableResourceWrapper<PlainTransport>;

#[rustler::resource_impl]
impl rustler::Resource for PlainTransportRef {}

#[derive(NifStruct)]
#[module = "Mediasoup.PlainTransport.Options"]
pub struct PlainTransportOptionsStruct {
    pub listen_info: JsonSerdeWrap<ListenInfo>,
    pub rtcp_listen_info: JsonSerdeWrap<Option<ListenInfo>>,
    pub rtcp_mux: Option<bool>,
    pub comedia: Option<bool>,
    pub enable_sctp: Option<bool>,
    pub max_send_message_size: Option<u32>,
    pub max_receive_message_size: Option<u32>,
    pub sctp_send_buffer_size: Option<u32>,
    pub sctp_per_stream_send_queue_limit: Option<u32>,
    pub sctp_max_receiver_window_buffer_size: Option<u32>,
    pub sctp_default_stream_buffered_amount_low_threshold: Option<u32>,
    pub enable_srtp: Option<bool>,
}
impl PlainTransportOptionsStruct {
    pub fn try_to_option(&self) -> Result<PlainTransportOptions, &'static str> {
        let mut option = PlainTransportOptions::new(self.listen_info.clone());

        option.rtcp_listen_info.clone_from(&self.rtcp_listen_info);
        if let Some(rtcp_mux) = self.rtcp_mux {
            option.rtcp_mux = rtcp_mux;
        }
        if let Some(comedia) = self.comedia {
            option.comedia = comedia;
        }
        if let Some(enable_sctp) = self.enable_sctp {
            option.enable_sctp = enable_sctp;
        }
        if let Some(max_send_message_size) = self.max_send_message_size {
            option.max_send_message_size = max_send_message_size;
        }
        if let Some(max_receive_message_size) = self.max_receive_message_size {
            option.max_receive_message_size = max_receive_message_size;
        }
        if let Some(sctp_send_buffer_size) = self.sctp_send_buffer_size {
            option.sctp_send_buffer_size = sctp_send_buffer_size;
        }
        if let Some(sctp_per_stream_send_queue_limit) = self.sctp_per_stream_send_queue_limit {
            option.sctp_per_stream_send_queue_limit = sctp_per_stream_send_queue_limit;
        }
        if let Some(sctp_max_receiver_window_buffer_size) =
            self.sctp_max_receiver_window_buffer_size
        {
            option.sctp_max_receiver_window_buffer_size = sctp_max_receiver_window_buffer_size;
        }
        if let Some(sctp_default_stream_buffered_amount_low_threshold) =
            self.sctp_default_stream_buffered_amount_low_threshold
        {
            option.sctp_default_stream_buffered_amount_low_threshold =
                sctp_default_stream_buffered_amount_low_threshold;
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
    from: Term,
) -> NifResult<Atom> {
    let transport = transport.get_resource()?;
    let option: PlainTransportRemoteParameters = option.clone();

    send_async_nif_result_with_from(env, from, async move {
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
    from: Term,
) -> NifResult<Atom> {
    let transport = transport.get_resource()?;

    send_async_nif_result_with_from(env, from, async move {
        transport
            .get_stats()
            .await
            .map(JsonSerdeWrap::new)
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif(name = "plain_transport_produce_async")]
pub fn plain_transport_produce(
    env: Env,
    transport: ResourceArc<PlainTransportRef>,
    option: ProducerOptionsStruct,
    from: Term,
) -> NifResult<Atom> {
    let transport = transport.get_resource()?;

    let option: ProducerOptions = option.to_option();

    send_async_nif_result_with_from(env, from, async move {
        transport
            .produce(option)
            .await
            .map(ProducerRef::new)
            .map(ResourceArc::new)
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif(name = "plain_transport_consume_async")]
pub fn plain_transport_consume(
    env: Env,
    transport: ResourceArc<PlainTransportRef>,
    option: ConsumerOptionsStruct,
    from: Term,
) -> NifResult<Atom> {
    let transport = transport.get_resource()?;

    let option: ConsumerOptions = option.to_option();

    send_async_nif_result_with_from(env, from, async move {
        transport
            .consume(option)
            .await
            .map(ConsumerRef::new)
            .map(ResourceArc::new)
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

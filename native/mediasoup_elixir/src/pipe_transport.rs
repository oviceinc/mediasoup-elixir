use crate::atoms;
use crate::consumer::{ConsumerOptionsStruct, ConsumerStruct};
use crate::data_structure::SerNumSctpStreams;
use crate::json_serde::JsonSerdeWrap;
use crate::producer::{ProducerOptionsStruct, ProducerStruct};
use crate::PipeTransportRef;
use futures_lite::future;
use mediasoup::data_structures::{SctpState, TransportListenIp, TransportTuple};
use mediasoup::pipe_transport::{
    PipeTransport, PipeTransportDump, PipeTransportOptions, PipeTransportRemoteParameters,
    PipeTransportStat,
};
use mediasoup::sctp_parameters::SctpParameters;
use mediasoup::srtp_parameters::SrtpParameters;

use mediasoup::transport::{Transport, TransportGeneric, TransportId};
use rustler::{Atom, Error, NifResult, NifStruct, ResourceArc};

#[derive(NifStruct)]
#[module = "Mediasoup.PipeTransport"]
pub struct PipeTransportStruct {
    id: JsonSerdeWrap<TransportId>,
    reference: ResourceArc<PipeTransportRef>,
}
impl PipeTransportStruct {
    pub fn from(transport: PipeTransport) -> Self {
        Self {
            id: transport.id().into(),
            reference: PipeTransportRef::resource(transport),
        }
    }
}

#[derive(NifStruct)]
#[module = "Mediasoup.PipeTransport.Options"]
pub struct PipeTransportOptionsStruct {
    /// Listening IP address.
    pub listen_ip: JsonSerdeWrap<TransportListenIp>,
    /// Fixed port to listen on instead of selecting automatically from Worker's port range.
    pub port: Option<u16>,
    /// Create a SCTP association.
    /// Default false.
    pub enable_sctp: Option<bool>,
    /// SCTP streams number.
    num_sctp_streams: Option<JsonSerdeWrap<SerNumSctpStreams>>,
    /// Maximum allowed size for SCTP messages sent by DataProducers.
    /// Default 268_435_456.
    pub max_sctp_message_size: Option<u32>,
    /// Maximum SCTP send buffer used by DataConsumers.
    /// Default 268_435_456.
    pub sctp_send_buffer_size: Option<u32>,
    /// Enable RTX and NACK for RTP retransmission. Useful if both Routers are located in different
    /// hosts and there is packet lost in the link. For this to work, both PipeTransports must
    /// enable this setting.
    /// Default false.
    pub enable_rtx: Option<bool>,
    /// Enable SRTP. Useful to protect the RTP and RTCP traffic if both Routers are located in
    /// different hosts. For this to work, connect() must be called with remote SRTP parameters.
    /// Default false.
    pub enable_srtp: Option<bool>,
}

impl PipeTransportOptionsStruct {
    pub fn try_to_option(self) -> rustler::NifResult<PipeTransportOptions> {
        let mut option = PipeTransportOptions::new(*self.listen_ip);

        option.port = self.port;

        if let Some(enable_sctp) = self.enable_sctp {
            option.enable_sctp = enable_sctp;
        }
        if let Some(num_sctp_streams) = self.num_sctp_streams {
            option.num_sctp_streams = num_sctp_streams.as_streams();
        }
        if let Some(max_sctp_message_size) = self.max_sctp_message_size {
            option.max_sctp_message_size = max_sctp_message_size;
        }
        if let Some(sctp_send_buffer_size) = self.sctp_send_buffer_size {
            option.sctp_send_buffer_size = sctp_send_buffer_size;
        }
        if let Some(enable_rtx) = self.enable_rtx {
            option.enable_rtx = enable_rtx;
        }
        if let Some(enable_srtp) = self.enable_srtp {
            option.enable_srtp = enable_srtp;
        }
        Ok(option)
    }
}

#[rustler::nif]
pub fn pipe_transport_id(transport: ResourceArc<PipeTransportRef>) -> NifResult<String> {
    let transport = transport.get_resource()?;
    Ok(transport.id().to_string())
}

#[rustler::nif]
pub fn pipe_transport_close(transport: ResourceArc<PipeTransportRef>) -> NifResult<(Atom,)> {
    transport.close();
    Ok((atoms::ok(),))
}

#[rustler::nif]
pub fn pipe_transport_tuple(
    transport: ResourceArc<PipeTransportRef>,
) -> NifResult<JsonSerdeWrap<TransportTuple>> {
    let transport = transport.get_resource()?;
    Ok(JsonSerdeWrap::new(transport.tuple()))
}

#[rustler::nif]
pub fn pipe_transport_consume(
    transport: ResourceArc<PipeTransportRef>,
    option: ConsumerOptionsStruct,
) -> NifResult<(Atom, ConsumerStruct)> {
    let transport = transport.get_resource()?;

    let option = option.to_option();

    let r = future::block_on(async move { transport.consume(option).await })
        .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;

    Ok((atoms::ok(), ConsumerStruct::from(r)))
}

#[rustler::nif]
pub fn pipe_transport_connect(
    transport: ResourceArc<PipeTransportRef>,
    option: JsonSerdeWrap<PipeTransportRemoteParameters>,
) -> NifResult<(Atom,)> {
    let transport = transport.get_resource()?;

    let option = option.clone();
    future::block_on(async move {
        return transport.connect(option).await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;
    Ok((atoms::ok(),))
}

#[rustler::nif]
pub fn pipe_transport_produce(
    transport: ResourceArc<PipeTransportRef>,
    option: ProducerOptionsStruct,
) -> NifResult<(Atom, ProducerStruct)> {
    let transport = transport.get_resource()?;
    let option = option.to_option();

    let producer = future::block_on(async move {
        return transport.produce(option).await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;
    Ok((atoms::ok(), ProducerStruct::from(producer)))
}

#[rustler::nif]
pub fn pipe_transport_get_stats(
    transport: ResourceArc<PipeTransportRef>,
) -> NifResult<JsonSerdeWrap<std::vec::Vec<PipeTransportStat>>> {
    let transport = transport.get_resource()?;

    let status = future::block_on(async move {
        return transport.get_stats().await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;

    Ok(JsonSerdeWrap::new(status))
}

#[rustler::nif]
pub fn pipe_transport_set_max_incoming_bitrate(
    transport: ResourceArc<PipeTransportRef>,
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
pub fn pipe_transport_sctp_state(
    transport: ResourceArc<PipeTransportRef>,
) -> NifResult<JsonSerdeWrap<Option<SctpState>>> {
    let transport = transport.get_resource()?;
    Ok(JsonSerdeWrap::new(transport.sctp_state()))
}
#[rustler::nif]
pub fn pipe_transport_sctp_parameters(
    transport: ResourceArc<PipeTransportRef>,
) -> NifResult<JsonSerdeWrap<Option<SctpParameters>>> {
    let transport = transport.get_resource()?;
    Ok(JsonSerdeWrap::new(transport.sctp_parameters()))
}

#[rustler::nif]
pub fn pipe_transport_srtp_parameters(
    transport: ResourceArc<PipeTransportRef>,
) -> NifResult<JsonSerdeWrap<Option<SrtpParameters>>> {
    let transport = transport.get_resource()?;
    Ok(JsonSerdeWrap::new(transport.srtp_parameters()))
}

#[rustler::nif]
pub fn pipe_transport_dump(
    transport: ResourceArc<PipeTransportRef>,
) -> NifResult<JsonSerdeWrap<PipeTransportDump>> {
    let transport = transport.get_resource()?;

    let dump = future::block_on(async move {
        return transport.dump().await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;

    Ok(JsonSerdeWrap::new(dump))
}

#[rustler::nif]
pub fn pipe_transport_event(
    transport: ResourceArc<PipeTransportRef>,
    pid: rustler::LocalPid,
) -> NifResult<(Atom,)> {
    let transport = transport.get_resource()?;

    crate::reg_callback_json_param!(pid, transport, on_sctp_state_change);
    crate::reg_callback_json_clone_param!(pid, transport, on_tuple);

    Ok((atoms::ok(),))
}

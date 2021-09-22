use crate::atoms;
use crate::consumer::ConsumerStruct;
use crate::json_serde::JsonSerdeWrap;
use crate::webrtc_transport::WebRtcTransportStruct;
use crate::RouterRef;
use futures_lite::future;
use mediasoup::data_structures::TransportListenIp;
use mediasoup::producer::ProducerId;
use mediasoup::router::{PipeToRouterOptions, Router, RouterDump, RouterId};
use mediasoup::rtp_parameters::{RtpCapabilities, RtpCapabilitiesFinalized};
use mediasoup::sctp_parameters::NumSctpStreams;
use mediasoup::webrtc_transport::{TransportListenIps, WebRtcTransportOptions};
use rustler::{Error, NifResult, NifStruct, ResourceArc};
use serde::{Deserialize, Serialize};

#[derive(NifStruct)]
#[module = "Mediasoup.Router"]
pub struct RouterStruct {
    id: JsonSerdeWrap<RouterId>,
    reference: ResourceArc<RouterRef>,
}
impl RouterStruct {
    pub fn from(router: Router) -> Self {
        Self {
            id: router.id().into(),
            reference: RouterRef::resource(router),
        }
    }
}

#[rustler::nif]
pub fn router_id(router: ResourceArc<RouterRef>) -> NifResult<String> {
    let router = router.get_resource()?;
    Ok(router.id().to_string())
}
#[rustler::nif]
pub fn router_close(router: ResourceArc<RouterRef>) -> NifResult<(rustler::Atom,)> {
    router.close();
    Ok((atoms::ok(),))
}
#[rustler::nif]
pub fn router_create_webrtc_transport(
    router: ResourceArc<RouterRef>,
    option: JsonSerdeWrap<SerWebRtcTransportOptions>,
) -> NifResult<(rustler::Atom, WebRtcTransportStruct)> {
    let router = router.get_resource()?;
    let option = option
        .try_to_option()
        .map_err(|error| Error::Term(Box::new(error.to_string())))?;

    let transport = future::block_on(async move {
        return router.create_webrtc_transport(option).await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;
    Ok((atoms::ok(), WebRtcTransportStruct::from(transport)))
}

#[rustler::nif]
pub fn router_rtp_capabilities(
    router: ResourceArc<RouterRef>,
) -> NifResult<JsonSerdeWrap<RtpCapabilitiesFinalized>> {
    let router = router.get_resource()?;

    Ok(JsonSerdeWrap::new(router.rtp_capabilities().clone()))
}

#[rustler::nif]
pub fn router_pipe_producer_to_router(
    router: ResourceArc<RouterRef>,
    producer_id: JsonSerdeWrap<ProducerId>,
    option: PipeToRouterOptionsStruct,
) -> NifResult<(rustler::Atom, PipeToRouterResultStruct)> {
    let router = router.get_resource()?;
    let producer_id = *producer_id;
    let option = option.try_to_option()?;

    let result = future::block_on(async move {
        return router.pipe_producer_to_router(producer_id, option).await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;

    return Ok((
        atoms::ok(),
        PipeToRouterResultStruct {
            pipe_consumer: ConsumerStruct::from(result.pipe_consumer),
            //            pipe_producer: ProducerStruct::from(result.pipe_producer.into_inner()),
        },
    ));
}

#[rustler::nif]
pub fn router_can_consume(
    router: ResourceArc<RouterRef>,
    producer_id: JsonSerdeWrap<ProducerId>,
    rtp_capabilities: JsonSerdeWrap<RtpCapabilities>,
) -> NifResult<bool> {
    let router = router.get_resource()?;
    let producer_id = *producer_id;
    let rtp_capabilities = rtp_capabilities.clone();

    let can_consume = router.can_consume(&producer_id, &rtp_capabilities);
    Ok(can_consume)
}
#[rustler::nif]
pub fn router_dump(router: ResourceArc<RouterRef>) -> NifResult<JsonSerdeWrap<RouterDump>> {
    let router = router.get_resource()?;
    let dump = future::block_on(async move {
        return router.dump().await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;

    Ok(JsonSerdeWrap::new(dump))
}

#[rustler::nif]
pub fn router_event(
    router: ResourceArc<RouterRef>,
    pid: rustler::LocalPid,
) -> NifResult<(rustler::Atom,)> {
    let router = router.get_resource()?;

    crate::reg_callback!(pid, router, on_close);
    crate::reg_callback!(pid, router, on_worker_close);

    /* TODO:
    {
        let pid = pid.clone();
        router
            .on_new_rtp_observer(move |observer| {
                let observer = match observer {
                    NewRtpObserver::AudioLevel(audioLevel) => send_msg_from_other_thread(pid.clone(), (atoms::on_new_rtp_observer(), audioLevel)),
                    _ => send_msg_from_other_thread(pid.clone(), (atoms::on_new_rtp_observer(), )),
                };
            })
            .detach();
    }
    */

    /* TODO: Can not create multiple instance for disposable
    {
        let pid = pid.clone();
        router
            .on_new_transport(move |transport| {
                match transport {
                    NewTransport::WebRtc(transport) => send_msg_from_other_thread(
                        pid.clone(),
                        WebRtcTransportStruct::from(transport.clone()),
                    ),
                    _ => (),
                };
            })
            .detach();
    }
    */

    Ok((atoms::ok(),))
}

#[derive(Serialize, Deserialize, Debug, PartialEq, Eq)]
struct SerNumSctpStreams {
    #[serde(rename = "OS")]
    pub os: u16,
    #[serde(rename = "MIS")]
    pub mis: u16,
}
impl SerNumSctpStreams {
    pub fn as_streams(&self) -> NumSctpStreams {
        NumSctpStreams {
            os: self.os,
            mis: self.mis,
        }
    }
}
#[derive(Serialize, Deserialize, Debug, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
pub struct SerWebRtcTransportOptions {
    listen_ips: Vec<TransportListenIp>,
    #[serde(skip_serializing_if = "Option::is_none")]
    enable_udp: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    enable_tcp: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    prefer_udp: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    prefer_tcp: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    initial_available_outgoing_bitrate: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    enable_sctp: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    num_sctp_streams: Option<SerNumSctpStreams>,
    #[serde(skip_serializing_if = "Option::is_none")]
    max_sctp_message_size: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    sctp_send_buffer_size: Option<u32>,
}

impl SerWebRtcTransportOptions {
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

#[derive(NifStruct)]
#[module = "Mediasoup.Router.PipeToRouterOptions"]
pub struct PipeToRouterOptionsStruct {
    /// Target Router instance.
    pub router: RouterStruct,
    /// IP used in the PipeTransport pair.
    ///
    /// Default `127.0.0.1`.
    //  listen_ip: Option<JsonSerdeWrap<TransportListenIp>>,
    /// Create a SCTP association.
    ///
    /// Default `true`.
    enable_sctp: Option<bool>,
    /// SCTP streams number.
    num_sctp_streams: Option<JsonSerdeWrap<SerNumSctpStreams>>,
    /// Enable RTX and NACK for RTP retransmission.
    ///
    /// Default `false`.
    pub enable_rtx: Option<bool>,
    /// Enable SRTP.
    ///
    /// Default `false`.
    pub enable_srtp: Option<bool>,
}

impl PipeToRouterOptionsStruct {
    pub fn try_to_option(self) -> rustler::NifResult<PipeToRouterOptions> {
        let router = self.router.reference.get_resource()?;

        let mut option = PipeToRouterOptions::new(router);

        if let Some(enable_sctp) = self.enable_sctp {
            option.enable_sctp = enable_sctp;
        }
        if let Some(num_sctp_streams) = self.num_sctp_streams {
            option.num_sctp_streams = num_sctp_streams.as_streams();
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

#[derive(NifStruct)]
#[module = "Mediasoup.Router.PipeToRouterResult"]
pub struct PipeToRouterResultStruct {
    pub pipe_consumer: ConsumerStruct,
    //    pub pipe_producer: ProducerStruct,// see PipedProducer
    //DataConsumer and DataProducer not implemented.
}

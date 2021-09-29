use crate::atoms;
use crate::consumer::ConsumerStruct;
use crate::data_structure::SerNumSctpStreams;
use crate::json_serde::JsonSerdeWrap;
use crate::producer::PipedProducerStruct;
use crate::webrtc_transport::{WebRtcTransportOptionsStruct, WebRtcTransportStruct};
use crate::RouterRef;
use futures_lite::future;
use mediasoup::producer::ProducerId;
use mediasoup::router::{PipeToRouterOptions, Router, RouterDump, RouterId};
use mediasoup::rtp_parameters::{RtpCapabilities, RtpCapabilitiesFinalized};
use rustler::{Error, NifResult, NifStruct, ResourceArc};

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
    option: WebRtcTransportOptionsStruct,
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
            pipe_producer: PipedProducerStruct::from(result.pipe_producer),
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
    pub pipe_producer: PipedProducerStruct,
    //DataConsumer and DataProducer not implemented.
}

use crate::atoms;
use crate::json_serde::JsonSerdeWrap;
use crate::pipe_transport::PipeTransportOptionsStruct;
use crate::webrtc_transport::WebRtcTransportOptionsStruct;
use crate::{PipeTransportRef, RouterRef, WebRtcTransportRef};
use futures_lite::future;
use mediasoup::producer::ProducerId;
use mediasoup::router::{RouterDump, RouterId, RouterOptions};
use mediasoup::rtp_parameters::{RtpCapabilities, RtpCapabilitiesFinalized, RtpCodecCapability};
use rustler::{Error, NifResult, NifStruct, ResourceArc};

#[rustler::nif]
pub fn router_id(router: ResourceArc<RouterRef>) -> NifResult<JsonSerdeWrap<RouterId>> {
    let router = router.get_resource()?;
    Ok(router.id().into())
}
#[rustler::nif]
pub fn router_close(router: ResourceArc<RouterRef>) -> NifResult<(rustler::Atom,)> {
    router.close();
    Ok((atoms::ok(),))
}
#[rustler::nif]
pub fn router_closed(router: ResourceArc<RouterRef>) -> NifResult<bool> {
    let router = router.get_resource()?;
    Ok(router.closed())
}

#[rustler::nif]
pub fn router_create_webrtc_transport(
    router: ResourceArc<RouterRef>,
    option: WebRtcTransportOptionsStruct,
) -> NifResult<(rustler::Atom, ResourceArc<WebRtcTransportRef>)> {
    let router = router.get_resource()?;
    let option = option
        .try_to_option()
        .map_err(|error| Error::Term(Box::new(error.to_string())))?;

    let transport = future::block_on(async move {
        return router.create_webrtc_transport(option).await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;
    Ok((atoms::ok(), WebRtcTransportRef::resource(transport)))
}

#[rustler::nif]
pub fn router_rtp_capabilities(
    router: ResourceArc<RouterRef>,
) -> NifResult<JsonSerdeWrap<RtpCapabilitiesFinalized>> {
    let router = router.get_resource()?;

    Ok(JsonSerdeWrap::new(router.rtp_capabilities().clone()))
}

#[rustler::nif]
pub fn router_create_pipe_transport(
    router: ResourceArc<RouterRef>,
    option: PipeTransportOptionsStruct,
) -> NifResult<(rustler::Atom, ResourceArc<PipeTransportRef>)> {
    let router = router.get_resource()?;
    let option = option.try_to_option()?;

    let result = future::block_on(async move {
        return router.create_pipe_transport(option).await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;

    Ok((atoms::ok(), PipeTransportRef::resource(result)))
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
    event_types: Vec<rustler::Atom>,
) -> NifResult<(rustler::Atom,)> {
    let router = router.get_resource()?;

    if event_types.contains(&atoms::on_close()) {
        crate::reg_callback!(pid, router, on_close);
    }
    if event_types.contains(&atoms::on_worker_close()) {
        crate::reg_callback!(pid, router, on_worker_close);
    }

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
#[module = "Mediasoup.Router.Options"]
pub struct RouterOptionsStruct {
    pub media_codecs: Option<JsonSerdeWrap<Vec<RtpCodecCapability>>>,
}

impl RouterOptionsStruct {
    pub fn to_option(&self) -> RouterOptions {
        let mut value = RouterOptions::default();
        if let Some(media_codecs) = &self.media_codecs {
            value.media_codecs = media_codecs.to_vec();
        }
        value
    }
}

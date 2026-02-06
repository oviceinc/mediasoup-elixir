use crate::json_serde::JsonSerdeWrap;
use crate::pipe_transport::{PipeTransportOptionsStruct, PipeTransportRef};
use crate::plain_transport::{PlainTransportOptionsStruct, PlainTransportRef};
use crate::webrtc_transport::{WebRtcTransportOptionsStruct, WebRtcTransportRef};
use crate::{atoms, send_async_nif_result_with_from, DisposableResourceWrapper};
use mediasoup::prelude::{RtpCapabilities, RtpCapabilitiesFinalized, RtpCodecCapability};
use mediasoup::producer::ProducerId;
use mediasoup::router::{Router, RouterId, RouterOptions};
use rustler::{Env, Error, NifResult, NifStruct, ResourceArc, Term};

pub type RouterRef = DisposableResourceWrapper<Router>;
#[rustler::resource_impl]
impl rustler::Resource for RouterRef {}

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

#[rustler::nif(name = "router_create_webrtc_transport_async")]
pub fn router_create_webrtc_transport(
    env: Env,
    router: ResourceArc<RouterRef>,
    option: WebRtcTransportOptionsStruct,
    from: Term,
) -> NifResult<rustler::Atom> {
    let router = router.get_resource()?;
    let option = option.try_to_option()?;

    send_async_nif_result_with_from(env, from, async move {
        router
            .create_webrtc_transport(option)
            .await
            .map(WebRtcTransportRef::new)
            .map(ResourceArc::new)
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif(name = "router_create_plain_transport_async")]
pub fn router_create_plain_transport(
    env: Env,
    router: ResourceArc<RouterRef>,
    option: PlainTransportOptionsStruct,
    from: Term,
) -> NifResult<rustler::Atom> {
    let router = router.get_resource()?;
    let option = option
        .try_to_option()
        .map_err(|error| Error::Term(Box::new(error.to_string())))?;

    send_async_nif_result_with_from(env, from, async move {
        router
            .create_plain_transport(option)
            .await
            .map(PlainTransportRef::new)
            .map(ResourceArc::new)
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif]
pub fn router_rtp_capabilities(
    router: ResourceArc<RouterRef>,
) -> NifResult<JsonSerdeWrap<RtpCapabilitiesFinalized>> {
    let router = router.get_resource()?;

    Ok(JsonSerdeWrap::new(router.rtp_capabilities().clone()))
}

#[rustler::nif(name = "router_create_pipe_transport_async")]
pub fn router_create_pipe_transport(
    env: Env,
    router: ResourceArc<RouterRef>,
    option: PipeTransportOptionsStruct,
    from: Term,
) -> NifResult<rustler::Atom> {
    let router = router.get_resource()?;
    let option = option.try_to_option()?;

    send_async_nif_result_with_from(env, from, async move {
        router
            .create_pipe_transport(option)
            .await
            .map(PipeTransportRef::new)
            .map(ResourceArc::new)
            .map_err(|error| format!("{}", error))
    })
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
#[rustler::nif(name = "router_dump_async")]
pub fn router_dump(
    env: Env,
    router: ResourceArc<RouterRef>,
    from: Term,
) -> NifResult<rustler::Atom> {
    let router = router.get_resource()?;

    send_async_nif_result_with_from(env, from, async move {
        router
            .dump()
            .await
            .map(JsonSerdeWrap::new)
            .map_err(|error| format!("{}", error))
    })
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

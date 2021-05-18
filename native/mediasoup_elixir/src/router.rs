use crate::atoms;
use crate::json_serde::{json_encode, JsonDecoder, JsonSerdeWrap};
use crate::webrtc_transport::WebRtcTransportStruct;
use crate::RouterRef;
use futures_lite::future;
use mediasoup::data_structures::TransportListenIp;
use mediasoup::producer::ProducerId;
use mediasoup::router::{Router, RouterId};
use mediasoup::rtp_parameters::RtpCapabilities;
use mediasoup::sctp_parameters::NumSctpStreams;
use mediasoup::webrtc_transport::{TransportListenIps, WebRtcTransportOptions};
use rustler::{Encoder, Env, Error, NifStruct, ResourceArc, Term};
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

pub fn router_id<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let router: ResourceArc<RouterRef> = args[0].decode()?;
    let router = match router.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    Ok(json_encode(&router.id().to_string(), env))
}
pub fn router_close<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let router: ResourceArc<RouterRef> = args[0].decode()?;
    router.close();
    Ok((atoms::ok(),).encode(env))
}
pub fn create_webrtc_transport<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let router: ResourceArc<RouterRef> = args[0].decode()?;
    let router = match router.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    let option: SerWebRtcTransportOptions = args[1].decode()?;
    let option = option.to_option().map_err(|e| Error::RaiseAtom(e))?;

    let r = match future::block_on(async move {
        return router.create_webrtc_transport(option).await;
    }) {
        Ok(transport) => (atoms::ok(), WebRtcTransportStruct::from(transport)).encode(env),
        Err(error) => (atoms::error(), format!("{}", error)).encode(env),
    };
    Ok(r)
}

pub fn router_rtp_capabilities<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let router: ResourceArc<RouterRef> = args[0].decode()?;
    let router = match router.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };

    Ok(json_encode(router.rtp_capabilities(), env))
}

pub fn router_can_consume<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let router: ResourceArc<RouterRef> = args[0].decode()?;
    let router = match router.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    let producer_id: ProducerId = JsonDecoder::decode(args[1])?;
    let rtp_capabilities: RtpCapabilities = JsonDecoder::decode(args[2])?;

    let can_consume = router.can_consume(&producer_id, &rtp_capabilities);
    Ok(rustler::Encoder::encode(&can_consume, env))
}
pub fn router_dump<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let router: ResourceArc<RouterRef> = args[0].decode()?;
    let router = match router.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };

    let dump = future::block_on(async move {
        return router.dump().await;
    })
    .map_err(|e| Error::RaiseTerm(Box::new(format!("{}", e))))?;

    Ok(json_encode(&dump, env))
}

pub fn router_event<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let router: ResourceArc<RouterRef> = args[0].decode()?;
    let router = match router.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    let pid: rustler::Pid = args[1].decode()?;

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

    Ok((atoms::ok(),).encode(env))
}

#[derive(Serialize, Deserialize, Debug, PartialEq, Eq)]
struct SerNumSctpStreams {
    #[serde(rename = "OS")]
    pub os: u16,
    #[serde(rename = "MIS")]
    pub mis: u16,
}
impl SerNumSctpStreams {
    pub fn to_native(self) -> NumSctpStreams {
        NumSctpStreams {
            os: self.os,
            mis: self.mis,
        }
    }
}
#[derive(Serialize, Deserialize, Debug, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
struct SerWebRtcTransportOptions {
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
crate::define_rustler_serde_by_json!(SerWebRtcTransportOptions);

impl SerWebRtcTransportOptions {
    pub fn to_option(self) -> Result<WebRtcTransportOptions, &'static str> {
        let ips = match self.listen_ips.first() {
            None => Err("Rquired least one ip"),
            Some(ip) => Ok(TransportListenIps::new(*ip)),
        }?;

        let ips = self.listen_ips[1..]
            .into_iter()
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
        if let Some(num_sctp_streams) = self.num_sctp_streams {
            option.num_sctp_streams = num_sctp_streams.to_native();
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

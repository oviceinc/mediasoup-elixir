use crate::{atoms, json_serde::JsonSerdeWrap, send_async_nif_result, WebRtcServerRef};
use mediasoup::{
    data_structures::Protocol,
    prelude::{ListenIp, WebRtcServerListenInfo, WebRtcServerListenInfos, WebRtcServerOptions},
    webrtc_server::WebRtcServerId,
};
use rustler::{Atom, Env, NifResult, NifStruct, ResourceArc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Copy, Clone, Eq, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct WebRtcServerListenInfoDeserializable {
    /// Network protocol.
    pub protocol: Protocol,
    /// Listening IP address.
    #[serde(flatten)]
    pub listen_ip: ListenIp,
    /// Listening port.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub port: Option<u16>,
}

impl WebRtcServerListenInfoDeserializable {
    pub fn into_info(&self) -> WebRtcServerListenInfo {
        WebRtcServerListenInfo {
            protocol: self.protocol,
            listen_ip: self.listen_ip,
            port: self.port,
        }
    }
}

#[derive(NifStruct)]
#[module = "Mediasoup.WebRtcServer.Options"]
pub struct WebRtcServerOptionsStruct {
    listen_infos: JsonSerdeWrap<Vec<WebRtcServerListenInfoDeserializable>>,
}

impl WebRtcServerOptionsStruct {
    pub fn try_to_option(&self) -> Result<WebRtcServerOptions, &'static str> {
        let infos = match self.listen_infos.first() {
            None => Err("Rquired least one ip"),
            Some(info) => Ok(WebRtcServerListenInfos::new(info.into_info())),
        }?;

        let infos = self.listen_infos[1..]
            .iter()
            .fold(infos, |infos, info| infos.insert(info.into_info()));

        Ok(WebRtcServerOptions::new(infos))
    }
}

#[rustler::nif]
pub fn webrtc_server_id(
    server: ResourceArc<WebRtcServerRef>,
) -> NifResult<JsonSerdeWrap<WebRtcServerId>> {
    let server = server.get_resource()?;
    Ok(server.id().into())
}

#[rustler::nif]
pub fn webrtc_server_close(server: ResourceArc<WebRtcServerRef>) -> NifResult<(Atom,)> {
    server.close();
    Ok((atoms::ok(),))
}

#[rustler::nif]
pub fn webrtc_server_closed(server: ResourceArc<WebRtcServerRef>) -> NifResult<bool> {
    match server.get_resource() {
        Ok(server) => Ok(server.closed()),
        Err(_) => Ok(true),
    }
}

#[rustler::nif(name = "webrtc_server_dump_async")]
pub fn webrtc_server_dump(
    env: Env,
    server: ResourceArc<WebRtcServerRef>,
) -> NifResult<(Atom, Atom)> {
    let server = server.get_resource()?;

    send_async_nif_result(env, async move {
        server
            .dump()
            .await
            .map(JsonSerdeWrap::new)
            .map_err(|error| format!("{}", error))
    })
}

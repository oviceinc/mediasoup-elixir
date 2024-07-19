use crate::{atoms, json_serde::JsonSerdeWrap, send_async_nif_result, DisposableResourceWrapper};
use mediasoup::prelude::{
    ListenInfo, WebRtcServer, WebRtcServerId, WebRtcServerListenInfos, WebRtcServerOptions,
};
use rustler::{Atom, Env, NifResult, NifStruct, ResourceArc};

pub type WebRtcServerRef = DisposableResourceWrapper<WebRtcServer>;

#[rustler::resource_impl]
impl rustler::Resource for WebRtcServerRef {}

#[derive(NifStruct)]
#[module = "Mediasoup.WebRtcServer.Options"]
pub struct WebRtcServerOptionsStruct {
    listen_infos: JsonSerdeWrap<Vec<ListenInfo>>,
}

impl WebRtcServerOptionsStruct {
    pub fn try_to_option(&self) -> Result<WebRtcServerOptions, &'static str> {
        let infos = match self.listen_infos.first() {
            None => Err("Rquired least one listen info"),
            Some(info) => Ok(WebRtcServerListenInfos::new(info.clone())),
        }?;

        let infos = self.listen_infos[1..]
            .iter()
            .fold(infos, |infos, info| infos.insert(info.clone()));

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

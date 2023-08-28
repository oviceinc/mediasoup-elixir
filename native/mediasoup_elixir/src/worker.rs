use crate::atoms;
use crate::json_serde::JsonSerdeWrap;
use crate::router::RouterOptionsStruct;
use crate::task;
use crate::webrtc_server::WebRtcServerOptionsStruct;
use crate::{
    send_async_nif_result, send_msg_from_other_thread, RouterRef, WebRtcServerRef, WorkerRef,
};
use mediasoup::worker::{
    WorkerDtlsFiles, WorkerId, WorkerLogLevel, WorkerLogTag, WorkerSettings, WorkerUpdateSettings,
};
use rustler::{Env, Error, NifResult, NifStruct, ResourceArc};
use std::path::PathBuf;
use std::sync::atomic::{AtomicUsize, Ordering};

static GLOBAL_WORKER_COUNT: AtomicUsize = AtomicUsize::new(0);

#[rustler::nif]
pub fn worker_global_count() -> Result<usize, Error> {
    Ok(GLOBAL_WORKER_COUNT.load(Ordering::Relaxed))
}

#[rustler::nif]
pub fn worker_id(worker: ResourceArc<WorkerRef>) -> NifResult<JsonSerdeWrap<WorkerId>> {
    let worker = worker.get_resource()?;

    Ok(JsonSerdeWrap::new(worker.id()))
}
#[rustler::nif]
pub fn worker_close(worker: ResourceArc<WorkerRef>) -> NifResult<(rustler::Atom,)> {
    worker.close();
    Ok((atoms::ok(),))
}

#[rustler::nif(name = "worker_create_router_async")]
pub fn worker_create_router(
    env: Env,
    worker: ResourceArc<WorkerRef>,
    option: RouterOptionsStruct,
) -> NifResult<(rustler::Atom, rustler::Atom)> {
    let worker = worker.get_resource()?;

    send_async_nif_result(env, async move {
        let option = option.to_option();
        worker
            .create_router(option)
            .await
            .map(RouterRef::resource)
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif(name = "worker_create_webrtc_server_async")]
pub fn worker_create_webrtc_server(
    env: Env,
    worker: ResourceArc<WorkerRef>,
    option: WebRtcServerOptionsStruct,
) -> NifResult<(rustler::Atom, rustler::Atom)> {
    let worker = worker.get_resource()?;
    let option = option
        .try_to_option()
        .map_err(|error| Error::Term(Box::new(error.to_string())))?;
    send_async_nif_result(env, async move {
        worker
            .create_webrtc_server(option)
            .await
            .map(WebRtcServerRef::resource)
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif(name = "worker_dump_async")]
pub fn worker_dump(
    env: Env,
    worker: ResourceArc<WorkerRef>,
) -> NifResult<(rustler::Atom, rustler::Atom)> {
    let worker = worker.get_resource()?;
    send_async_nif_result(env, async move {
        worker
            .dump()
            .await
            .map(JsonSerdeWrap::new)
            .map_err(|error| format!("{}", error))
    })
}
#[rustler::nif]
pub fn worker_closed(worker: ResourceArc<WorkerRef>) -> Result<bool, Error> {
    let worker = worker.get_resource()?;

    Ok(worker.closed())
}
#[rustler::nif(name = "worker_update_settings_async")]
pub fn worker_update_settings(
    env: Env,
    worker: ResourceArc<WorkerRef>,
    settings: WorkerUpdateableSettingsStruct,
) -> NifResult<(rustler::Atom, rustler::Atom)> {
    let worker = worker.get_resource()?;

    let settings = settings.try_to_setting()?;

    send_async_nif_result(env, async move {
        worker
            .update_settings(settings)
            .await
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif]
pub fn worker_event(
    worker: ResourceArc<WorkerRef>,
    pid: rustler::LocalPid,
    event_types: Vec<rustler::Atom>,
) -> NifResult<(rustler::Atom,)> {
    let worker = worker.get_resource()?;

    /* TODO: Can not create multiple instance for disposable
    If we need this, implement at elixir side.
    {
        let pid = pid.clone();
        worker
            .on_new_router(move |router| {
                send_msg_from_other_thread(
                    pid.clone(),
                    (atoms::on_new_router(), RouterStruct::from(router.clone())),
                );
            })
            .detach();
    }*/
    if event_types.contains(&atoms::on_close()) {
        crate::reg_callback!(pid, worker, on_close);
    }

    if event_types.contains(&atoms::on_dead()) {
        worker
            .on_dead(move |reason| match reason {
                Ok(_) => send_msg_from_other_thread(pid, (atoms::on_dead(),)),
                Err(err) => send_msg_from_other_thread(pid, (atoms::on_dead(), err.to_string())),
            })
            .detach();
    }

    Ok((atoms::ok(),))
}

fn create_worker_impl(
    env: Env,
    settings: WorkerSettings,
) -> NifResult<(rustler::Atom, rustler::Atom)> {
    send_async_nif_result(env, async move {
        let worker_manager = task::worker_manager();
        worker_manager
            .create_worker(settings)
            .await
            .map(|worker| {
                GLOBAL_WORKER_COUNT.fetch_add(1, Ordering::Relaxed);
                worker
                    .on_close(|| {
                        GLOBAL_WORKER_COUNT.fetch_sub(1, Ordering::Relaxed);
                    })
                    .detach();
                WorkerRef::resource(worker)
            })
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif(name = "create_worker_async")]
pub fn create_worker_no_arg(env: Env) -> NifResult<(rustler::Atom, rustler::Atom)> {
    create_worker_impl(env, WorkerSettings::default())
}

#[rustler::nif(name = "create_worker_async")]
pub fn create_worker(
    env: Env,
    settings: WorkerSettingsStruct,
) -> NifResult<(rustler::Atom, rustler::Atom)> {
    let settings = settings.try_to_setting()?;
    create_worker_impl(env, settings)
}

#[derive(NifStruct)]
#[module = "Mediasoup.Worker.UpdateableSettings"]
pub struct WorkerUpdateableSettingsStruct {
    pub log_level: Option<JsonSerdeWrap<String>>,
    pub log_tags: Option<JsonSerdeWrap<Vec<String>>>,
}

impl WorkerUpdateableSettingsStruct {
    fn try_to_setting(&self) -> Result<WorkerUpdateSettings, Error> {
        let mut value = WorkerUpdateSettings::default();

        if let Some(log_level) = &self.log_level {
            value.log_level = Some(log_level_from_string(log_level)?)
        }
        if let Some(log_tags) = &self.log_tags {
            value.log_tags = Some(log_tags_from_strings(log_tags)?)
        }
        Ok(value)
    }
}

#[derive(NifStruct)]
#[module = "Mediasoup.Worker.Settings"]
pub struct WorkerSettingsStruct {
    pub log_level: Option<JsonSerdeWrap<String>>,
    pub log_tags: Option<JsonSerdeWrap<Vec<String>>>,
    pub rtc_min_port: Option<u16>,
    pub rtc_max_port: Option<u16>,
    pub dtls_certificate_file: Option<String>,
    pub dtls_private_key_file: Option<String>,
}

impl WorkerSettingsStruct {
    fn try_to_setting(&self) -> Result<WorkerSettings, Error> {
        let mut value = WorkerSettings::default();
        if let Some(log_level) = &self.log_level {
            value.log_level = log_level_from_string(log_level)?
        }
        if let Some(log_tags) = &self.log_tags {
            value.log_tags = log_tags_from_strings(log_tags)?
        }
        let default_range = value.rtc_ports_range;
        let minport = self.rtc_min_port.unwrap_or(*default_range.start());
        let maxport = self.rtc_max_port.unwrap_or(*default_range.end());
        value.rtc_ports_range = minport..=maxport;

        if let (Some(cert), Some(private)) =
            (&self.dtls_certificate_file, &self.dtls_private_key_file)
        {
            value.dtls_files = Some(WorkerDtlsFiles {
                certificate: PathBuf::from(cert),
                private_key: PathBuf::from(private),
            });
        }

        Ok(value)
    }
}

fn log_level_from_string(s: &str) -> NifResult<WorkerLogLevel> {
    return match s {
        "debug" => Ok(WorkerLogLevel::Debug),
        "error" => Ok(WorkerLogLevel::Error),
        "Err" => Ok(WorkerLogLevel::Error), // workaround for :error to "Err" by serde
        "none" => Ok(WorkerLogLevel::None),
        "warn" => Ok(WorkerLogLevel::Warn),
        _ => Err(Error::RaiseTerm(Box::new(format!(
            "invalid type {} for WorkerLogLevel",
            s
        )))),
    };
}

fn log_tag_from_string(s: &str) -> NifResult<WorkerLogTag> {
    return match s {
        "info" => Ok(WorkerLogTag::Info),
        "ice" => Ok(WorkerLogTag::Ice),
        "dtls" => Ok(WorkerLogTag::Dtls),
        "rtp" => Ok(WorkerLogTag::Rtp),
        "srtp" => Ok(WorkerLogTag::Srtp),
        "rtcp" => Ok(WorkerLogTag::Rtcp),
        "rtx" => Ok(WorkerLogTag::Rtx),
        "bwe" => Ok(WorkerLogTag::Bwe),
        "score" => Ok(WorkerLogTag::Score),
        "simulcast" => Ok(WorkerLogTag::Simulcast),
        "svc" => Ok(WorkerLogTag::Svc),
        "sctp" => Ok(WorkerLogTag::Sctp),
        "message" => Ok(WorkerLogTag::Message),
        _ => Err(Error::RaiseTerm(Box::new(format!(
            "invalid type {} for WorkerLogTag",
            s
        )))),
    };
}

fn log_tags_from_strings(v: &[String]) -> NifResult<Vec<WorkerLogTag>> {
    v.iter().map(|s| log_tag_from_string(s)).collect()
}

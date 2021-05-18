use crate::atoms;
use crate::json_serde::{json_encode, JsonSerdeWrap};
use crate::router::RouterStruct;
use crate::{send_msg_from_other_thread, WorkerRef};
use futures_lite::future;
use mediasoup::router::RouterOptions;
use mediasoup::rtp_parameters::RtpCodecCapability;
use mediasoup::worker::{
    Worker, WorkerDtlsFiles, WorkerId, WorkerLogLevel, WorkerLogTag, WorkerSettings,
    WorkerUpdateSettings,
};
use mediasoup::worker_manager::WorkerManager;
use once_cell::sync::Lazy;
use rustler::{Encoder, Env, Error, NifResult, NifStruct, ResourceArc, Term};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::sync::Mutex;

#[derive(NifStruct)]
#[module = "Mediasoup.Worker"]
pub struct WorkerStruct {
    id: JsonSerdeWrap<WorkerId>,
    reference: ResourceArc<WorkerRef>,
}
impl WorkerStruct {
    pub fn from(worker: Worker) -> Self {
        Self {
            id: worker.id().into(),
            reference: WorkerRef::resource(worker),
        }
    }
}
static WORKER_MANAGER: Lazy<Mutex<WorkerManager>> = Lazy::new(|| Mutex::new(WorkerManager::new()));

pub fn worker_id<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let worker: ResourceArc<WorkerRef> = args[0].decode()?;
    let worker = match worker.unwrap() {
        Some(w) => w,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    Ok(json_encode(&worker.id(), env))
}
pub fn worker_close<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let worker: ResourceArc<WorkerRef> = args[0].decode()?;
    worker.close();
    Ok((atoms::ok(),).encode(env))
}
pub fn create_router<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let worker: ResourceArc<WorkerRef> = args[0].decode()?;
    let worker = match worker.unwrap() {
        Some(w) => w,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    let option: SerRouterOptions = args[1].decode()?;
    let option = option.to_option()?;

    let r = match future::block_on(async move {
        return worker.create_router(option).await;
    }) {
        Ok(router) => (atoms::ok(), RouterStruct::from(router)).encode(env),
        Err(error) => (atoms::error(), format!("{}", error)).encode(env),
    };
    Ok(r)
}
pub fn worker_dump<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let worker: ResourceArc<WorkerRef> = args[0].decode()?;
    let worker = match worker.unwrap() {
        Some(w) => w,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };

    let dump = future::block_on(async move {
        return worker.dump().await;
    })
    .map_err(|e| Error::RaiseTerm(Box::new(format!("{}", e))))?;

    Ok(json_encode(&dump, env))
}
pub fn worker_closed<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let worker: ResourceArc<WorkerRef> = args[0].decode()?;
    let worker = match worker.unwrap() {
        Some(w) => w,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    Ok(json_encode(&worker.closed(), env))
}
pub fn worker_update_settings<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let worker: ResourceArc<WorkerRef> = args[0].decode()?;
    let worker = match worker.unwrap() {
        Some(w) => w,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    let settings: SerWorkerUpdateSettings = args[1].decode()?;
    let settings = settings.to_setting()?;

    future::block_on(async move {
        return worker.update_settings(settings).await;
    })
    .map_err(|e| Error::RaiseTerm(Box::new(format!("{}", e))))?;

    Ok((atoms::ok(),).encode(env))
}

pub fn worker_event<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let worker: ResourceArc<WorkerRef> = args[0].decode()?;
    let worker = match worker.unwrap() {
        Some(w) => w,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    let pid: rustler::Pid = args[1].decode()?;

    /* TODO: Can not create multiple instance for disposable
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
    crate::reg_callback!(pid, worker, on_close);
    {
        let pid = pid.clone();
        worker
            .on_dead(move |reason| match reason {
                Ok(_) => send_msg_from_other_thread(pid.clone(), (atoms::on_dead(),)),
                Err(err) => {
                    send_msg_from_other_thread(pid.clone(), (atoms::on_dead(), err.to_string()))
                }
            })
            .detach();
    }

    Ok((atoms::ok(),).encode(env))
}

pub fn create_worker_no_arg<'a>(env: Env<'a>, _args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let worker_manager = WORKER_MANAGER
        .lock()
        .map_err(|_e| Error::RaiseAtom("worker_manager lock error"))?;
    let r = match future::block_on(async move {
        return worker_manager
            .create_worker(WorkerSettings::default())
            .await;
    }) {
        Ok(worker) => (atoms::ok(), WorkerStruct::from(worker)).encode(env),
        Err(error) => (atoms::error(), format!("{}", error)).encode(env),
    };
    Ok(r)
}

pub fn create_worker<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let settings: SerWorkerSettings = args[0].decode()?;
    let settings = settings.to_setting()?;
    let worker_manager = WORKER_MANAGER
        .lock()
        .map_err(|_e| Error::RaiseAtom("worker_manager lock error"))?;

    let r = match future::block_on(async move {
        return worker_manager.create_worker(settings).await;
    }) {
        Ok(worker) => (atoms::ok(), WorkerStruct::from(worker)).encode(env),
        Err(error) => (atoms::error(), format!("{}", error)).encode(env),
    };
    Ok(r)
}

#[derive(Serialize, Deserialize, Debug, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
struct SerRouterOptions {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub media_codecs: Option<Vec<RtpCodecCapability>>,
}
crate::define_rustler_serde_by_json!(SerRouterOptions);

impl SerRouterOptions {
    fn to_option(&self) -> Result<RouterOptions, Error> {
        let mut value = RouterOptions::default();
        if let Some(media_codecs) = &self.media_codecs {
            value.media_codecs = media_codecs.to_vec();
        }
        Ok(value)
    }
}

#[derive(Serialize, Deserialize, Debug, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
struct SerWorkerUpdateSettings {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub log_level: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub log_tags: Option<Vec<String>>,
}
crate::define_rustler_serde_by_json!(SerWorkerUpdateSettings);

impl SerWorkerUpdateSettings {
    fn to_setting(&self) -> Result<WorkerUpdateSettings, Error> {
        let mut value = WorkerUpdateSettings::default();

        if let Some(log_level) = &self.log_level {
            value.log_level = Some(log_level_from_string(log_level.as_str())?)
        }
        if let Some(log_tags) = &self.log_tags {
            value.log_tags = Some(log_tags_from_strings(&log_tags)?)
        }
        Ok(value)
    }
}

#[derive(Serialize, Deserialize, Debug, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
struct SerWorkerSettings {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub log_level: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub log_tags: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub rtc_min_port: Option<u16>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub rtc_max_port: Option<u16>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub dtls_certificate_file: Option<PathBuf>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub dtls_private_key_file: Option<PathBuf>,
}
crate::define_rustler_serde_by_json!(SerWorkerSettings);

impl SerWorkerSettings {
    fn to_setting(&self) -> Result<WorkerSettings, Error> {
        let mut value = WorkerSettings::default();
        if let Some(log_level) = &self.log_level {
            value.log_level = log_level_from_string(log_level.as_str())?
        }
        if let Some(log_tags) = &self.log_tags {
            value.log_tags = log_tags_from_strings(&log_tags)?
        }
        let default_range = value.rtc_ports_range;
        let minport = self.rtc_min_port.unwrap_or(*default_range.start());
        let maxport = self.rtc_max_port.unwrap_or(*default_range.end());
        value.rtc_ports_range = minport..=maxport;

        if let (Some(cert), Some(private)) =
            (&self.dtls_certificate_file, &self.dtls_private_key_file)
        {
            value.dtls_files = Some(WorkerDtlsFiles {
                certificate: cert.clone(),
                private_key: private.clone(),
            });
        }

        Ok(value)
    }
}

fn log_level_from_string(s: &str) -> NifResult<WorkerLogLevel> {
    return match s {
        "debug" => Ok(WorkerLogLevel::Debug),
        "error" => Ok(WorkerLogLevel::Error),
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

fn log_tags_from_strings(v: &Vec<String>) -> NifResult<Vec<WorkerLogTag>> {
    v.iter().map(|s| log_tag_from_string(s)).collect()
}

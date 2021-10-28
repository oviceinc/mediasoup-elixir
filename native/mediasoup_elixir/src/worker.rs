use crate::atoms;
use crate::json_serde::JsonSerdeWrap;
use crate::router::{RouterOptionsStruct, RouterStruct};
use crate::{send_msg_from_other_thread, WorkerRef};
use futures_lite::future;
use mediasoup::worker::{
    Worker, WorkerDtlsFiles, WorkerDump, WorkerId, WorkerLogLevel, WorkerLogTag, WorkerSettings,
    WorkerUpdateSettings,
};
use mediasoup::worker_manager::WorkerManager;
use rustler::{Error, NifResult, NifStruct, ResourceArc};
use std::path::PathBuf;

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

#[rustler::nif]
pub fn worker_create_router(
    worker: ResourceArc<WorkerRef>,
    option: RouterOptionsStruct,
) -> NifResult<(rustler::Atom, RouterStruct)> {
    let worker = worker.get_resource()?;

    let option = option.to_option();

    let router = future::block_on(async move {
        return worker.create_router(option).await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;

    Ok((atoms::ok(), RouterStruct::from(router)))
}

#[rustler::nif]
pub fn worker_dump(worker: ResourceArc<WorkerRef>) -> NifResult<JsonSerdeWrap<WorkerDump>> {
    let worker = worker.get_resource()?;

    let dump = future::block_on(async move {
        return worker.dump().await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;

    Ok(JsonSerdeWrap::new(dump))
}
#[rustler::nif]
pub fn worker_closed(worker: ResourceArc<WorkerRef>) -> Result<bool, Error> {
    let worker = worker.get_resource()?;

    Ok(worker.closed())
}
#[rustler::nif]
pub fn worker_update_settings(
    worker: ResourceArc<WorkerRef>,
    settings: WorkerUpdateableSettingsStruct,
) -> NifResult<(rustler::Atom,)> {
    let worker = worker.get_resource()?;

    let settings = settings.try_to_setting()?;

    future::block_on(async move {
        return worker.update_settings(settings).await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;

    Ok((atoms::ok(),))
}

#[rustler::nif]
pub fn worker_event(
    worker: ResourceArc<WorkerRef>,
    pid: rustler::LocalPid,
    event_types: Vec<rustler::Atom>,
) -> NifResult<(rustler::Atom,)> {
    let worker = worker.get_resource()?;

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

fn create_worker_impl(settings: WorkerSettings) -> NifResult<(rustler::Atom, WorkerStruct)> {
    let worker_manager = WorkerManager::new();

    let worker = future::block_on(async move {
        return worker_manager.create_worker(settings).await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;
    Ok((atoms::ok(), WorkerStruct::from(worker)))
}

#[rustler::nif(name = "create_worker")]
pub fn create_worker_no_arg() -> NifResult<(rustler::Atom, WorkerStruct)> {
    create_worker_impl(WorkerSettings::default())
}

#[rustler::nif]
pub fn create_worker(settings: WorkerSettingsStruct) -> NifResult<(rustler::Atom, WorkerStruct)> {
    let settings = settings.try_to_setting()?;
    create_worker_impl(settings)
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
            value.log_level = Some(log_level_from_string(log_level.as_str())?)
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
            value.log_level = log_level_from_string(log_level.as_str())?
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

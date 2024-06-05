use crate::atoms;
use crate::send_msg_from_other_thread;
use log::{Level, Metadata, Record};
use rustler::{NifStruct, NifUnitEnum};
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Mutex;

struct LoggerProxy {
    pid: Mutex<Option<rustler::LocalPid>>,
    max_level: AtomicUsize,
}

impl LoggerProxy {
    fn logger_proxy_process(&self) -> Option<rustler::LocalPid> {
        let guard = self.pid.lock().unwrap();
        guard.clone()
    }
    fn set_proxy_process(&self, pid: rustler::LocalPid) {
        if let Ok(ref mut mutex) = self.pid.lock() {
            **mutex = Some(pid);
        }
    }
    fn set_max_level(&self, filter: log::LevelFilter) {
        log::set_max_level(filter);
        self.max_level.store(filter as usize, Ordering::Relaxed);
    }
}

fn ignore_log(record: &Record) -> bool {
    // Ignore this as it is an error log with no way to deal with it.
    record
        .args()
        .to_string()
        .ends_with("Channel already closed")
}

impl log::Log for LoggerProxy {
    fn enabled(&self, metadata: &Metadata) -> bool {
        (metadata.level() as usize) < self.max_level.load(Ordering::Relaxed)
    }

    fn log(&self, record: &Record) {
        if ignore_log(record) {
            return;
        }
        if let Option::Some(pid) = self.logger_proxy_process() {
            let rec = LoggerProxyRecord {
                level: record.level().into(),
                target: record.target().to_string(),
                body: record.args().to_string(),
                module_path: record.module_path().map(str::to_string),
                file: record.file().map(str::to_string),
                line: record.line(),
            };
            send_msg_from_other_thread(pid, rec);
        }
    }
    fn flush(&self) {}
}

#[rustler::nif]
pub fn init_env_logger() {
    env_logger::init();
}

static LOGGER_PROXY: LoggerProxy = LoggerProxy {
    pid: Mutex::new(None),
    max_level: AtomicUsize::new(log::LevelFilter::Info as usize),
};

#[rustler::nif]
pub fn set_logger_proxy_process(
    pid: rustler::LocalPid,
    filter: NifLevelFilter,
) -> rustler::NifResult<rustler::Atom> {
    let _ = log::set_logger(&LOGGER_PROXY);

    LOGGER_PROXY.set_proxy_process(pid);
    LOGGER_PROXY.set_max_level(filter.into());

    Ok(atoms::ok())
}

#[rustler::nif]
pub fn debug_logger(level: NifLevel, message: String) -> rustler::NifResult<rustler::Atom> {
    match level {
        NifLevel::Error => log::log!(log::Level::Error, "{}", message),
        NifLevel::Warn => log::log!(log::Level::Warn, "{}", message),
        NifLevel::Info => log::log!(log::Level::Info, "{}", message),
        NifLevel::Debug => log::log!(log::Level::Debug, "{}", message),
    }

    Ok(atoms::ok())
}

#[derive(NifStruct)]
#[module = "Mediasoup.LoggerProxy.Record"]
pub struct LoggerProxyRecord {
    level: NifLevel,
    target: String,
    body: String,
    module_path: Option<String>,
    file: Option<String>,
    line: Option<u32>,
}

#[derive(NifUnitEnum)]
enum NifLevel {
    Error,
    Warn,
    Info,
    Debug,
}

#[derive(NifUnitEnum)]
enum NifLevelFilter {
    Off,
    Error,
    Warn,
    Info,
    Debug,
    Trace,
}

impl From<Level> for NifLevel {
    fn from(level: Level) -> NifLevel {
        match level {
            Level::Error => NifLevel::Error,
            Level::Warn => NifLevel::Warn,
            Level::Info => NifLevel::Info,
            Level::Debug => NifLevel::Debug,
            Level::Trace => NifLevel::Debug,
        }
    }
}

impl From<NifLevelFilter> for log::LevelFilter {
    fn from(level: NifLevelFilter) -> log::LevelFilter {
        match level {
            NifLevelFilter::Off => log::LevelFilter::Off,
            NifLevelFilter::Error => log::LevelFilter::Error,
            NifLevelFilter::Warn => log::LevelFilter::Warn,
            NifLevelFilter::Info => log::LevelFilter::Info,
            NifLevelFilter::Debug => log::LevelFilter::Debug,
            NifLevelFilter::Trace => log::LevelFilter::Trace,
        }
    }
}

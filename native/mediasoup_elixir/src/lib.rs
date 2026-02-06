mod atoms;
mod consumer;
mod data_consumer;
mod data_producer;
mod data_structure;
mod json_serde;
mod logger;
mod macros;
mod pipe_transport;
mod plain_transport;
mod producer;
mod resource;
mod router;
mod supported_rtp_capabilities;
mod task;
mod term_box;
mod webrtc_server;
mod webrtc_transport;
mod worker;

use crate::resource::DisposableResourceWrapper;
use crate::term_box::TermBox;

use futures_lite::future;
use rustler::{Atom, Encoder, Env, LocalPid, NifResult, OwnedEnv};

pub fn send_msg_from_other_thread<T>(pid: LocalPid, value: T)
where
    T: rustler::Encoder + Send + 'static,
{
    let mut my_env = OwnedEnv::new();
    task::spawn(async move {
        let _ = my_env.send_and_clear(&pid, |env| value.encode(env));
    })
    .detach();
}

pub fn send_async_nif_result<T, E, Fut>(env: Env, future: Fut) -> NifResult<(Atom, Atom)>
where
    T: Encoder,
    E: Encoder,
    Fut: future::Future<Output = Result<T, E>> + Send + 'static,
{
    let pid = env.pid();
    let mut my_env = OwnedEnv::new();
    let result_key = atoms::mediasoup_async_nif_result();
    task::spawn(async move {
        let result = future.await;
        match result {
            Ok(worker) => {
                let _ = my_env
                    .send_and_clear(&pid, |env| (result_key, (atoms::ok(), worker)).encode(env));
            }
            Err(err) => {
                let _ = my_env
                    .send_and_clear(&pid, |env| (result_key, (atoms::error(), err)).encode(env));
            }
        }
    })
    .detach();

    Ok((atoms::ok(), result_key))
}

pub fn send_async_nif_result_with_from<T, Fut>(
    env: Env,
    from: rustler::Term,
    future: Fut,
) -> NifResult<Atom>
where
    T: Encoder,
    Fut: future::Future<Output = T> + Send + 'static,
{
    let pid = env.pid();
    let mut my_env = OwnedEnv::new();

    let from = TermBox::new(from);
    task::spawn(async move {
        let result = future.await;

        let _ = my_env.send_and_clear(&pid, |env| {
            (atoms::mediasoup_async_nif_result(), from.get(env), result).encode(env)
        });
    })
    .detach();

    Ok(atoms::ok())
}

rustler::init!("Elixir.Mediasoup.Nif");

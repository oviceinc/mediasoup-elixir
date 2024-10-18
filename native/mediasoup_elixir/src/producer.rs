use crate::json_serde::JsonSerdeWrap;
use crate::{atoms, send_async_nif_result_with_from};
use crate::{send_msg_from_other_thread, DisposableResourceWrapper};
use mediasoup::producer::{Producer, ProducerId, ProducerOptions, ProducerScore, ProducerType};
use mediasoup::rtp_parameters::{MediaKind, RtpParameters};
use rustler::{Atom, Env, NifResult, NifStruct, ResourceArc, Term};

pub type ProducerRef = DisposableResourceWrapper<Producer>;
#[rustler::resource_impl]
impl rustler::Resource for ProducerRef {}

#[rustler::nif]
pub fn producer_id(producer: ResourceArc<ProducerRef>) -> NifResult<JsonSerdeWrap<ProducerId>> {
    let producer = producer.get_resource()?;
    Ok(producer.id().into())
}

#[rustler::nif]
pub fn producer_kind(producer: ResourceArc<ProducerRef>) -> NifResult<JsonSerdeWrap<MediaKind>> {
    let producer = producer.get_resource()?;
    Ok(producer.kind().into())
}

#[rustler::nif]
pub fn producer_type(producer: ResourceArc<ProducerRef>) -> NifResult<JsonSerdeWrap<ProducerType>> {
    let producer = producer.get_resource()?;
    Ok(producer.r#type().into())
}

#[rustler::nif]
pub fn producer_rtp_parameters(
    producer: ResourceArc<ProducerRef>,
) -> NifResult<JsonSerdeWrap<RtpParameters>> {
    let producer = producer.get_resource()?;
    Ok(producer.rtp_parameters().clone().into())
}

#[rustler::nif]
pub fn producer_close(producer: ResourceArc<ProducerRef>) -> NifResult<(Atom,)> {
    producer.close();
    Ok((atoms::ok(),))
}
#[rustler::nif(name = "producer_pause_async")]
pub fn producer_pause(env: Env, producer: ResourceArc<ProducerRef>, from: Term) -> NifResult<Atom> {
    let producer = producer.get_resource()?;

    send_async_nif_result_with_from(env, from, async move {
        producer.pause().await.map_err(|error| format!("{}", error))
    })
}

#[rustler::nif]
pub fn producer_closed(producer: ResourceArc<ProducerRef>) -> NifResult<bool> {
    match producer.get_resource() {
        Ok(producer) => Ok(producer.closed()),
        Err(_) => Ok(true),
    }
}

#[rustler::nif]
pub fn producer_paused(producer: ResourceArc<ProducerRef>) -> NifResult<bool> {
    let producer = producer.get_resource()?;
    Ok(producer.paused())
}

#[rustler::nif]
pub fn producer_score(
    producer: ResourceArc<ProducerRef>,
) -> NifResult<JsonSerdeWrap<std::vec::Vec<ProducerScore>>> {
    let producer = producer.get_resource()?;
    Ok(JsonSerdeWrap::new(producer.score()))
}

#[rustler::nif(name = "producer_get_stats_async")]
pub fn producer_get_stats(
    env: Env,
    producer: ResourceArc<ProducerRef>,
    from: Term,
) -> NifResult<Atom> {
    let producer = producer.get_resource()?;

    send_async_nif_result_with_from(env, from, async move {
        producer
            .get_stats()
            .await
            .map(JsonSerdeWrap::new)
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif(name = "producer_resume_async")]
pub fn producer_resume(
    env: Env,
    producer: ResourceArc<ProducerRef>,
    from: Term,
) -> NifResult<Atom> {
    let producer = producer.get_resource()?;

    send_async_nif_result_with_from(env, from, async move {
        producer
            .resume()
            .await
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif(name = "producer_dump_async")]
pub fn producer_dump(env: Env, producer: ResourceArc<ProducerRef>, from: Term) -> NifResult<Atom> {
    let producer = producer.get_resource()?;

    send_async_nif_result_with_from(env, from, async move {
        producer
            .dump()
            .await
            .map(JsonSerdeWrap::new)
            .map_err(|error| format!("{}", error))
    })
}
#[rustler::nif]
pub fn producer_event(
    producer: ResourceArc<ProducerRef>,
    pid: rustler::LocalPid,
    event_types: Vec<Atom>,
) -> NifResult<(rustler::Atom,)> {
    let producer = producer.get_resource()?;

    if event_types.contains(&atoms::on_close()) {
        crate::reg_callback!(pid, producer, on_close);
    }
    if event_types.contains(&atoms::on_pause()) {
        crate::reg_callback!(pid, producer, on_pause);
    }
    if event_types.contains(&atoms::on_resume()) {
        crate::reg_callback!(pid, producer, on_resume);
    }

    if event_types.contains(&atoms::on_video_orientation_change()) {
        producer
            .on_video_orientation_change(move |orientation| {
                send_msg_from_other_thread(
                    pid,
                    (
                        atoms::on_video_orientation_change(),
                        JsonSerdeWrap::new(orientation),
                    ),
                );
            })
            .detach();
    }
    if event_types.contains(&atoms::on_score()) {
        //let pid = pid.clone();
        producer
            .on_score(move |score| {
                send_msg_from_other_thread(
                    pid,
                    (atoms::on_score(), JsonSerdeWrap::new(score.to_vec())),
                );
            })
            .detach();
    }

    Ok((atoms::ok(),))
}

#[derive(NifStruct)]
#[module = "Mediasoup.Producer.Options"]
pub struct ProducerOptionsStruct {
    pub id: Option<JsonSerdeWrap<ProducerId>>,
    pub kind: JsonSerdeWrap<MediaKind>,
    pub rtp_parameters: JsonSerdeWrap<RtpParameters>,
    pub paused: Option<bool>,
    pub key_frame_request_delay: Option<u32>,
}

impl ProducerOptionsStruct {
    pub fn to_option(&self) -> ProducerOptions {
        let mut option = match &self.id {
            Some(id) => {
                ProducerOptions::new_pipe_transport(**id, *self.kind, self.rtp_parameters.clone())
            }
            None => ProducerOptions::new(*self.kind, self.rtp_parameters.clone()),
        };

        option.paused = self.paused.unwrap_or(option.paused);
        option.key_frame_request_delay = self
            .key_frame_request_delay
            .unwrap_or(option.key_frame_request_delay);

        option
    }
}

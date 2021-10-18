use crate::atoms;
use crate::json_serde::JsonSerdeWrap;
use crate::{send_msg_from_other_thread, PipedProducerRef, ProducerRef};
use futures_lite::future;
use mediasoup::producer::{
    PipedProducer, Producer, ProducerDump, ProducerId, ProducerOptions, ProducerScore,
    ProducerStat, ProducerType,
};
use mediasoup::rtp_parameters::{MediaKind, RtpParameters};
use rustler::{Atom, Error, NifResult, NifStruct, ResourceArc};

#[derive(NifStruct)]
#[module = "Mediasoup.Producer"]
pub struct ProducerStruct {
    id: JsonSerdeWrap<ProducerId>,
    kind: JsonSerdeWrap<MediaKind>,
    r#type: JsonSerdeWrap<ProducerType>,
    rtp_parameters: JsonSerdeWrap<RtpParameters>,
    reference: ResourceArc<ProducerRef>,
}
impl ProducerStruct {
    pub fn from(producer: Producer) -> Self {
        Self {
            id: producer.id().into(),
            kind: producer.kind().into(),
            r#type: producer.r#type().into(),
            rtp_parameters: producer.rtp_parameters().clone().into(),
            reference: ProducerRef::resource(producer),
        }
    }
}

#[rustler::nif]
pub fn producer_id(producer: ResourceArc<ProducerRef>) -> NifResult<String> {
    let producer = producer.get_resource()?;
    Ok(producer.id().to_string())
}

#[rustler::nif]
pub fn producer_close(producer: ResourceArc<ProducerRef>) -> NifResult<(Atom,)> {
    producer.close();
    Ok((atoms::ok(),))
}
#[rustler::nif]
pub fn producer_pause(producer: ResourceArc<ProducerRef>) -> NifResult<(rustler::Atom,)> {
    let producer = producer.get_resource()?;

    future::block_on(async move {
        return producer.pause().await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;
    Ok((atoms::ok(),))
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

#[rustler::nif]
pub fn producer_get_stats(
    producer: ResourceArc<ProducerRef>,
) -> NifResult<JsonSerdeWrap<std::vec::Vec<ProducerStat>>> {
    let producer = producer.get_resource()?;

    let stats = future::block_on(async move {
        return producer.get_stats().await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;

    Ok(JsonSerdeWrap::new(stats))
}

#[rustler::nif]
pub fn producer_resume(producer: ResourceArc<ProducerRef>) -> NifResult<(rustler::Atom,)> {
    let producer = producer.get_resource()?;

    future::block_on(async move {
        return producer.resume().await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;
    Ok((atoms::ok(),))
}

#[rustler::nif]
pub fn producer_dump(producer: ResourceArc<ProducerRef>) -> NifResult<JsonSerdeWrap<ProducerDump>> {
    let producer = producer.get_resource()?;

    let dump = future::block_on(async move {
        return producer.dump().await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;

    Ok(JsonSerdeWrap::new(dump))
}
#[rustler::nif]
pub fn producer_event(
    producer: ResourceArc<ProducerRef>,
    pid: rustler::LocalPid,
    event_filter: Vec<Atom>,
) -> NifResult<(rustler::Atom,)> {
    let producer = producer.get_resource()?;

    if event_filter.contains(&atoms::on_close()) {
        crate::reg_callback!(pid, producer, on_close);
    }
    if event_filter.contains(&atoms::on_pause()) {
        crate::reg_callback!(pid, producer, on_pause);
    }
    if event_filter.contains(&atoms::on_resume()) {
        crate::reg_callback!(pid, producer, on_resume);
    }

    if event_filter.contains(&atoms::on_video_orientation_change()) {
        let pid = pid.clone();
        producer
            .on_video_orientation_change(move |orientation| {
                send_msg_from_other_thread(
                    pid.clone(),
                    (
                        atoms::on_video_orientation_change(),
                        JsonSerdeWrap::new(orientation),
                    ),
                );
            })
            .detach();
    }
    if event_filter.contains(&atoms::on_score()) {
        //let pid = pid.clone();
        producer
            .on_score(move |score| {
                send_msg_from_other_thread(
                    pid.clone(),
                    (atoms::on_score(), JsonSerdeWrap::new(score.clone())),
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

#[derive(NifStruct)]
#[module = "Mediasoup.PipedProducer"]
pub struct PipedProducerStruct {
    reference: ResourceArc<PipedProducerRef>,
}
impl PipedProducerStruct {
    pub fn from(producer: PipedProducer) -> Self {
        Self {
            reference: PipedProducerRef::resource(producer),
        }
    }
}

#[rustler::nif]
pub fn piped_producer_into_producer(
    piped_producer: ResourceArc<PipedProducerRef>,
) -> NifResult<(Atom, ProducerStruct)> {
    let mut piped_producer = piped_producer
        .0
        .lock()
        .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;

    if let Some(piped_producer) = piped_producer.take() {
        Ok((
            atoms::ok(),
            ProducerStruct::from(piped_producer.into_inner()),
        ))
    } else {
        Err(Error::Term(Box::new("closed")))
    }
}

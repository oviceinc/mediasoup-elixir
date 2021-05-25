use crate::atoms;
use crate::json_serde::JsonSerdeWrap;
use crate::{send_msg_from_other_thread, ProducerRef};
use futures_lite::future;
use mediasoup::producer::{Producer, ProducerDump, ProducerId};
use rustler::{Atom, Error, NifResult, NifStruct, ResourceArc};

#[derive(NifStruct)]
#[module = "Mediasoup.Producer"]
pub struct ProducerStruct {
    id: JsonSerdeWrap<ProducerId>,
    reference: ResourceArc<ProducerRef>,
}
impl ProducerStruct {
    pub fn from(producer: Producer) -> Self {
        Self {
            id: producer.id().into(),
            reference: ProducerRef::resource(producer),
        }
    }
}

#[rustler::nif]
pub fn producer_id<'a>(producer: ResourceArc<ProducerRef>) -> NifResult<String> {
    let producer = producer
        .unwrap()
        .ok_or(Error::Term(Box::new(atoms::terminated())))?;
    Ok(producer.id().to_string())
}

#[rustler::nif]
pub fn producer_close<'a>(producer: ResourceArc<ProducerRef>) -> NifResult<(Atom,)> {
    producer.close();
    Ok((atoms::ok(),))
}
#[rustler::nif]
pub fn producer_pause<'a>(producer: ResourceArc<ProducerRef>) -> NifResult<(rustler::Atom,)> {
    let producer = producer
        .unwrap()
        .ok_or(Error::Term(Box::new(atoms::terminated())))?;

    future::block_on(async move {
        return producer.pause().await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;
    Ok((atoms::ok(),))
}
#[rustler::nif]
pub fn producer_resume<'a>(producer: ResourceArc<ProducerRef>) -> NifResult<(rustler::Atom,)> {
    let producer = producer
        .unwrap()
        .ok_or(Error::Term(Box::new(atoms::terminated())))?;

    future::block_on(async move {
        return producer.resume().await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;
    Ok((atoms::ok(),))
}

#[rustler::nif]
pub fn producer_dump<'a>(
    producer: ResourceArc<ProducerRef>,
) -> NifResult<JsonSerdeWrap<ProducerDump>> {
    let producer = producer
        .unwrap()
        .ok_or(Error::Term(Box::new(atoms::terminated())))?;

    let dump = future::block_on(async move {
        return producer.dump().await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;

    Ok(JsonSerdeWrap::new(dump))
}
#[rustler::nif]
pub fn producer_event<'a>(
    producer: ResourceArc<ProducerRef>,
    pid: rustler::LocalPid,
) -> NifResult<(rustler::Atom,)> {
    let producer = producer
        .unwrap()
        .ok_or(Error::Term(Box::new(atoms::terminated())))?;

    crate::reg_callback!(pid, producer, on_close);
    crate::reg_callback!(pid, producer, on_pause);
    crate::reg_callback!(pid, producer, on_resume);

    {
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
    {
        let pid = pid.clone();
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

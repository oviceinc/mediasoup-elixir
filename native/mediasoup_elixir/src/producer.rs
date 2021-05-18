use crate::atoms;
use crate::json_serde::{JsonEncoder, JsonSerdeWrap};
use crate::{send_msg_from_other_thread, ProducerRef};
use futures_lite::future;
use mediasoup::producer::{Producer, ProducerId};
use rustler::{Encoder, Env, Error, NifStruct, ResourceArc, Term};

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

pub fn producer_id<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let producer: ResourceArc<ProducerRef> = args[0].decode()?;
    let producer = match producer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    Ok(producer.id().encode(env))
}
pub fn producer_close<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let producer: ResourceArc<ProducerRef> = args[0].decode()?;
    producer.close();
    Ok((atoms::ok(),).encode(env))
}
pub fn producer_pause<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let producer: ResourceArc<ProducerRef> = args[0].decode()?;
    let producer = match producer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };

    let r = match future::block_on(async move {
        return producer.pause().await;
    }) {
        Ok(_) => (atoms::ok(),).encode(env),
        Err(error) => (atoms::error(), format!("{}", error)).encode(env),
    };
    Ok(r)
}
pub fn producer_resume<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let producer: ResourceArc<ProducerRef> = args[0].decode()?;
    let producer = match producer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };

    let r = match future::block_on(async move {
        return producer.resume().await;
    }) {
        Ok(_) => (atoms::ok(),).encode(env),
        Err(error) => (atoms::error(), format!("{}", error)).encode(env),
    };
    Ok(r)
}

pub fn producer_dump<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let producer: ResourceArc<ProducerRef> = args[0].decode()?;
    let producer = match producer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };

    let dump = future::block_on(async move {
        return producer.dump().await;
    })
    .map_err(|e| Error::RaiseTerm(Box::new(format!("{}", e))))?;

    Ok(dump.encode(env))
}
pub fn producer_event<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let producer: ResourceArc<ProducerRef> = args[0].decode()?;
    let producer = match producer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    let pid: rustler::Pid = args[1].decode()?;

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

    Ok((atoms::ok(),).encode(env))
}

use crate::atoms;
use crate::json_serde::{json_encode, JsonSerdeWrap};
use crate::send_msg_from_other_thread;
use crate::ConsumerRef;
use futures_lite::future;
use mediasoup::consumer::{Consumer, ConsumerId, ConsumerLayers};
use mediasoup::producer::ProducerId;
use mediasoup::rtp_parameters::{MediaKind, RtpParameters};
use rustler::{Encoder, Env, Error, NifStruct, ResourceArc, Term};

#[derive(NifStruct)]
#[module = "Mediasoup.Consumer"]
pub struct ConsumerStruct {
    id: JsonSerdeWrap<ConsumerId>,
    producer_id: JsonSerdeWrap<ProducerId>,
    kind: JsonSerdeWrap<MediaKind>,
    rtp_parameters: JsonSerdeWrap<RtpParameters>,
    reference: ResourceArc<ConsumerRef>,
}
impl ConsumerStruct {
    pub fn from(consumer: Consumer) -> Self {
        Self {
            id: consumer.id().into(),
            producer_id: consumer.producer_id().into(),
            kind: consumer.kind().into(),
            rtp_parameters: consumer.rtp_parameters().clone().into(),
            reference: ConsumerRef::resource(consumer),
        }
    }
}

pub fn consumer_id<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let consumer: ResourceArc<ConsumerRef> = args[0].decode()?;
    let consumer = match consumer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    Ok(json_encode(&consumer.id(), env))
}
pub fn consumer_close<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let consumer: ResourceArc<ConsumerRef> = args[0].decode()?;
    consumer.close();
    Ok((atoms::ok(),).encode(env))
}
pub fn consumer_closed<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let consumer: ResourceArc<ConsumerRef> = args[0].decode()?;
    let consumer = match consumer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    Ok(consumer.closed().encode(env))
}

pub fn consumer_paused<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let consumer: ResourceArc<ConsumerRef> = args[0].decode()?;
    let consumer = match consumer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    Ok(consumer.paused().encode(env))
}

pub fn consumer_producer_paused<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let consumer: ResourceArc<ConsumerRef> = args[0].decode()?;
    let consumer = match consumer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    Ok(consumer.producer_paused().encode(env))
}
pub fn consumer_priority<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let consumer: ResourceArc<ConsumerRef> = args[0].decode()?;
    let consumer = match consumer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    Ok(consumer.priority().encode(env))
}
pub fn consumer_score<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let consumer: ResourceArc<ConsumerRef> = args[0].decode()?;
    let consumer = match consumer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    Ok(json_encode(&consumer.score(), env))
}
pub fn consumer_preferred_layers<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let consumer: ResourceArc<ConsumerRef> = args[0].decode()?;
    let consumer = match consumer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    Ok(json_encode(&consumer.preferred_layers(), env))
}
pub fn consumer_current_layers<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let consumer: ResourceArc<ConsumerRef> = args[0].decode()?;
    let consumer = match consumer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    Ok(json_encode(&consumer.current_layers(), env))
}

pub fn consumer_get_stats<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let consumer: ResourceArc<ConsumerRef> = args[0].decode()?;
    let consumer = match consumer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    let status = future::block_on(async move {
        return consumer.get_stats().await;
    })
    .map_err(|e| Error::RaiseTerm(Box::new(format!("{}", e))))?;

    Ok(json_encode(&status, env))
}
pub fn consumer_pause<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let consumer: ResourceArc<ConsumerRef> = args[0].decode()?;
    let consumer = match consumer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };

    let r = match future::block_on(async move {
        return consumer.pause().await;
    }) {
        Ok(_) => (atoms::ok(),).encode(env),
        Err(error) => (atoms::error(), format!("{}", error)).encode(env),
    };
    return Ok(r);
}
pub fn consumer_resume<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let consumer: ResourceArc<ConsumerRef> = args[0].decode()?;
    let consumer = match consumer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };

    let r = match future::block_on(async move {
        return consumer.resume().await;
    }) {
        Ok(_) => (atoms::ok(),).encode(env),
        Err(error) => (atoms::error(), format!("{}", error)).encode(env),
    };
    return Ok(r);
}

pub fn consumer_set_preferred_layers<'a>(
    env: Env<'a>,
    args: &[Term<'a>],
) -> Result<Term<'a>, Error> {
    let consumer: ResourceArc<ConsumerRef> = args[0].decode()?;
    let consumer = match consumer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    let layer: JsonSerdeWrap<ConsumerLayers> = args[1].decode()?;

    let r = match future::block_on(async move {
        return consumer.set_preferred_layers(*layer).await;
    }) {
        Ok(_) => (atoms::ok(),).encode(env),
        Err(error) => (atoms::error(), format!("{}", error)).encode(env),
    };
    return Ok(r);
}

pub fn consumer_set_priority<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let consumer: ResourceArc<ConsumerRef> = args[0].decode()?;
    let consumer = match consumer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    let priority: u8 = args[1].decode()?;
    let r = match future::block_on(async move {
        return consumer.set_priority(priority).await;
    }) {
        Ok(_) => (atoms::ok(),).encode(env),
        Err(error) => (atoms::error(), format!("{}", error)).encode(env),
    };
    return Ok(r);
}
pub fn consumer_unset_priority<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let consumer: ResourceArc<ConsumerRef> = args[0].decode()?;
    let consumer = match consumer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };

    let r = match future::block_on(async move {
        return consumer.unset_priority().await;
    }) {
        Ok(_) => (atoms::ok(),).encode(env),
        Err(error) => (atoms::error(), format!("{}", error)).encode(env),
    };
    return Ok(r);
}

pub fn consumer_request_key_frame<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let consumer: ResourceArc<ConsumerRef> = args[0].decode()?;
    let consumer = match consumer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };

    let r = match future::block_on(async move {
        return consumer.request_key_frame().await;
    }) {
        Ok(_) => (atoms::ok(),).encode(env),
        Err(error) => (atoms::error(), format!("{}", error)).encode(env),
    };
    return Ok(r);
}

pub fn consumer_dump<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let consumer: ResourceArc<ConsumerRef> = args[0].decode()?;
    let consumer = match consumer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };

    let dump = future::block_on(async move {
        return consumer.dump().await;
    })
    .map_err(|e| Error::RaiseTerm(Box::new(format!("{}", e))))?;

    Ok(json_encode(&dump, env))
}

pub fn consumer_event<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let consumer: ResourceArc<ConsumerRef> = args[0].decode()?;
    let consumer = match consumer.unwrap() {
        Some(v) => v,
        None => return Ok((atoms::error(), atoms::terminated()).encode(env)),
    };
    let pid: rustler::Pid = args[1].decode()?;

    crate::reg_callback!(pid, consumer, on_close);
    crate::reg_callback!(pid, consumer, on_pause);
    crate::reg_callback!(pid, consumer, on_resume);
    crate::reg_callback!(pid, consumer, on_producer_pause);
    crate::reg_callback!(pid, consumer, on_producer_resume);

    crate::reg_callback!(pid, consumer, on_producer_close);
    crate::reg_callback!(pid, consumer, on_transport_close);

    {
        let pid = pid.clone();
        consumer
            .on_layers_change(move |layer| {
                send_msg_from_other_thread(
                    pid.clone(),
                    (atoms::on_layers_change(), JsonSerdeWrap::new(layer.clone())),
                );
            })
            .detach();
    }
    {
        let pid = pid.clone();
        consumer
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

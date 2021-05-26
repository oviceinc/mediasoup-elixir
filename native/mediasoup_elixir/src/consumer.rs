use crate::atoms;
use crate::json_serde::JsonSerdeWrap;
use crate::send_msg_from_other_thread;
use crate::ConsumerRef;
use futures_lite::future;
use mediasoup::consumer::{
    Consumer, ConsumerDump, ConsumerId, ConsumerLayers, ConsumerScore, ConsumerStats,
};
use mediasoup::producer::ProducerId;
use mediasoup::rtp_parameters::{MediaKind, RtpParameters};
use rustler::{Atom, Error, NifResult, NifStruct, ResourceArc};

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

#[rustler::nif]
pub fn consumer_id(consumer: ResourceArc<ConsumerRef>) -> NifResult<JsonSerdeWrap<ConsumerId>> {
    let consumer = consumer
        .unwrap()
        .ok_or_else(|| Error::Term(Box::new(atoms::terminated())))?;
    Ok(JsonSerdeWrap::new(consumer.id()))
}
#[rustler::nif]
pub fn consumer_close(consumer: ResourceArc<ConsumerRef>) -> NifResult<(Atom,)> {
    consumer.close();
    Ok((atoms::ok(),))
}
#[rustler::nif]
pub fn consumer_closed(consumer: ResourceArc<ConsumerRef>) -> NifResult<bool> {
    let consumer = consumer
        .unwrap()
        .ok_or_else(|| Error::Term(Box::new(atoms::terminated())))?;
    Ok(consumer.closed())
}

#[rustler::nif]
pub fn consumer_paused(consumer: ResourceArc<ConsumerRef>) -> NifResult<bool> {
    let consumer = consumer
        .unwrap()
        .ok_or_else(|| Error::Term(Box::new(atoms::terminated())))?;
    Ok(consumer.paused())
}

#[rustler::nif]
pub fn consumer_producer_paused(consumer: ResourceArc<ConsumerRef>) -> NifResult<bool> {
    let consumer = consumer
        .unwrap()
        .ok_or_else(|| Error::Term(Box::new(atoms::terminated())))?;
    Ok(consumer.producer_paused())
}
#[rustler::nif]
pub fn consumer_priority(consumer: ResourceArc<ConsumerRef>) -> NifResult<u8> {
    let consumer = consumer
        .unwrap()
        .ok_or_else(|| Error::Term(Box::new(atoms::terminated())))?;
    Ok(consumer.priority())
}
#[rustler::nif]
pub fn consumer_score(
    consumer: ResourceArc<ConsumerRef>,
) -> NifResult<JsonSerdeWrap<ConsumerScore>> {
    let consumer = consumer
        .unwrap()
        .ok_or_else(|| Error::Term(Box::new(atoms::terminated())))?;
    Ok(JsonSerdeWrap::new(consumer.score()))
}
#[rustler::nif]
pub fn consumer_preferred_layers(
    consumer: ResourceArc<ConsumerRef>,
) -> NifResult<JsonSerdeWrap<Option<ConsumerLayers>>> {
    let consumer = consumer
        .unwrap()
        .ok_or_else(|| Error::Term(Box::new(atoms::terminated())))?;
    Ok(JsonSerdeWrap::new(consumer.preferred_layers()))
}
#[rustler::nif]
pub fn consumer_current_layers(
    consumer: ResourceArc<ConsumerRef>,
) -> NifResult<JsonSerdeWrap<Option<ConsumerLayers>>> {
    let consumer = consumer
        .unwrap()
        .ok_or_else(|| Error::Term(Box::new(atoms::terminated())))?;
    Ok(JsonSerdeWrap::new(consumer.current_layers()))
}

#[rustler::nif]
pub fn consumer_get_stats(
    consumer: ResourceArc<ConsumerRef>,
) -> NifResult<JsonSerdeWrap<ConsumerStats>> {
    let consumer = consumer
        .unwrap()
        .ok_or_else(|| Error::Term(Box::new(atoms::terminated())))?;
    let status = future::block_on(async move {
        return consumer.get_stats().await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;

    Ok(JsonSerdeWrap::new(status))
}
#[rustler::nif]
pub fn consumer_pause(consumer: ResourceArc<ConsumerRef>) -> NifResult<(Atom,)> {
    let consumer = consumer
        .unwrap()
        .ok_or_else(|| Error::Term(Box::new(atoms::terminated())))?;

    future::block_on(async move {
        return consumer.pause().await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;
    Ok((atoms::ok(),))
}
#[rustler::nif]
pub fn consumer_resume(consumer: ResourceArc<ConsumerRef>) -> NifResult<(Atom,)> {
    let consumer = consumer
        .unwrap()
        .ok_or_else(|| Error::Term(Box::new(atoms::terminated())))?;

    future::block_on(async move {
        return consumer.resume().await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;
    Ok((atoms::ok(),))
}

#[rustler::nif]
pub fn consumer_set_preferred_layers(
    consumer: ResourceArc<ConsumerRef>,
    layer: JsonSerdeWrap<ConsumerLayers>,
) -> NifResult<(Atom,)> {
    let consumer = consumer
        .unwrap()
        .ok_or_else(|| Error::Term(Box::new(atoms::terminated())))?;

    future::block_on(async move {
        return consumer.set_preferred_layers(*layer).await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;
    Ok((atoms::ok(),))
}

#[rustler::nif]
pub fn consumer_set_priority(
    consumer: ResourceArc<ConsumerRef>,
    priority: u8,
) -> NifResult<(Atom,)> {
    let consumer = consumer
        .unwrap()
        .ok_or_else(|| Error::Term(Box::new(atoms::terminated())))?;
    future::block_on(async move {
        return consumer.set_priority(priority).await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;
    Ok((atoms::ok(),))
}
#[rustler::nif]
pub fn consumer_unset_priority(consumer: ResourceArc<ConsumerRef>) -> NifResult<(Atom,)> {
    let consumer = consumer
        .unwrap()
        .ok_or_else(|| Error::Term(Box::new(atoms::terminated())))?;

    future::block_on(async move {
        return consumer.unset_priority().await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;
    Ok((atoms::ok(),))
}

#[rustler::nif]
pub fn consumer_request_key_frame(consumer: ResourceArc<ConsumerRef>) -> NifResult<(Atom,)> {
    let consumer = consumer
        .unwrap()
        .ok_or_else(|| Error::Term(Box::new(atoms::terminated())))?;

    future::block_on(async move {
        return consumer.request_key_frame().await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;
    Ok((atoms::ok(),))
}

#[rustler::nif]
pub fn consumer_dump(consumer: ResourceArc<ConsumerRef>) -> NifResult<JsonSerdeWrap<ConsumerDump>> {
    let consumer = consumer
        .unwrap()
        .ok_or_else(|| Error::Term(Box::new(atoms::terminated())))?;

    let dump = future::block_on(async move {
        return consumer.dump().await;
    })
    .map_err(|error| Error::Term(Box::new(format!("{}", error))))?;

    Ok(JsonSerdeWrap::new(dump))
}

#[rustler::nif]
pub fn consumer_event(
    consumer: ResourceArc<ConsumerRef>,
    pid: rustler::LocalPid,
) -> NifResult<(Atom,)> {
    let consumer = consumer
        .unwrap()
        .ok_or_else(|| Error::Term(Box::new(atoms::terminated())))?;

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
                    (atoms::on_layers_change(), JsonSerdeWrap::new(*layer)),
                );
            })
            .detach();
    }
    {
        //let pid = pid.clone();
        consumer
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

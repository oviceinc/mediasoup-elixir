use crate::json_serde::JsonSerdeWrap;
use crate::{
    atoms, send_async_nif_result_with_from, send_msg_from_other_thread, DisposableResourceWrapper,
};
use mediasoup::consumer::{
    Consumer, ConsumerId, ConsumerLayers, ConsumerOptions, ConsumerScore, ConsumerType,
};
use mediasoup::prelude::{MediaKind, RtpCapabilities, RtpParameters};
use mediasoup::producer::ProducerId;
use rustler::{Atom, Env, NifResult, NifStruct, ResourceArc, Term};

pub type ConsumerRef = DisposableResourceWrapper<Consumer>;
#[rustler::resource_impl]
impl rustler::Resource for ConsumerRef {}

#[rustler::nif]
pub fn consumer_id(consumer: ResourceArc<ConsumerRef>) -> NifResult<JsonSerdeWrap<ConsumerId>> {
    let consumer = consumer.get_resource()?;
    Ok(consumer.id().into())
}

#[rustler::nif]
pub fn consumer_producer_id(
    consumer: ResourceArc<ConsumerRef>,
) -> NifResult<JsonSerdeWrap<ProducerId>> {
    let consumer = consumer.get_resource()?;
    Ok(consumer.producer_id().into())
}

#[rustler::nif]
pub fn consumer_kind(consumer: ResourceArc<ConsumerRef>) -> NifResult<JsonSerdeWrap<MediaKind>> {
    let consumer = consumer.get_resource()?;
    Ok(consumer.kind().into())
}

#[rustler::nif]
pub fn consumer_type(consumer: ResourceArc<ConsumerRef>) -> NifResult<JsonSerdeWrap<ConsumerType>> {
    let consumer = consumer.get_resource()?;
    Ok(consumer.r#type().into())
}

#[rustler::nif]
pub fn consumer_rtp_parameters(
    consumer: ResourceArc<ConsumerRef>,
) -> NifResult<JsonSerdeWrap<RtpParameters>> {
    let consumer = consumer.get_resource()?;
    Ok(consumer.rtp_parameters().clone().into())
}

#[rustler::nif]
pub fn consumer_close(consumer: ResourceArc<ConsumerRef>) -> NifResult<(Atom,)> {
    consumer.close();
    Ok((atoms::ok(),))
}
#[rustler::nif]
pub fn consumer_closed(consumer: ResourceArc<ConsumerRef>) -> NifResult<bool> {
    match consumer.get_resource() {
        Ok(consumer) => Ok(consumer.closed()),
        Err(_) => Ok(true),
    }
}

#[rustler::nif]
pub fn consumer_paused(consumer: ResourceArc<ConsumerRef>) -> NifResult<bool> {
    let consumer = consumer.get_resource()?;
    Ok(consumer.paused())
}

#[rustler::nif]
pub fn consumer_producer_paused(consumer: ResourceArc<ConsumerRef>) -> NifResult<bool> {
    let consumer = consumer.get_resource()?;
    Ok(consumer.producer_paused())
}
#[rustler::nif]
pub fn consumer_priority(consumer: ResourceArc<ConsumerRef>) -> NifResult<u8> {
    let consumer = consumer.get_resource()?;
    Ok(consumer.priority())
}
#[rustler::nif]
pub fn consumer_score(
    consumer: ResourceArc<ConsumerRef>,
) -> NifResult<JsonSerdeWrap<ConsumerScore>> {
    let consumer = consumer.get_resource()?;
    Ok(JsonSerdeWrap::new(consumer.score()))
}
#[rustler::nif]
pub fn consumer_preferred_layers(
    consumer: ResourceArc<ConsumerRef>,
) -> NifResult<JsonSerdeWrap<Option<ConsumerLayers>>> {
    let consumer = consumer.get_resource()?;
    Ok(JsonSerdeWrap::new(consumer.preferred_layers()))
}
#[rustler::nif]
pub fn consumer_current_layers(
    consumer: ResourceArc<ConsumerRef>,
) -> NifResult<JsonSerdeWrap<Option<ConsumerLayers>>> {
    let consumer = consumer.get_resource()?;
    Ok(JsonSerdeWrap::new(consumer.current_layers()))
}

#[rustler::nif(name = "consumer_get_stats_async")]
pub fn consumer_get_stats(
    env: Env,
    consumer: ResourceArc<ConsumerRef>,
    from: Term,
) -> NifResult<Atom> {
    let consumer = consumer.get_resource()?;

    send_async_nif_result_with_from(env, from, async move {
        consumer
            .get_stats()
            .await
            .map(JsonSerdeWrap::new)
            .map_err(|error| format!("{}", error))
    })
}
#[rustler::nif(name = "consumer_pause_async")]
pub fn consumer_pause(env: Env, consumer: ResourceArc<ConsumerRef>, from: Term) -> NifResult<Atom> {
    let consumer = consumer.get_resource()?;

    send_async_nif_result_with_from(env, from, async move {
        consumer.pause().await.map_err(|error| format!("{}", error))
    })
}
#[rustler::nif(name = "consumer_resume_async")]
pub fn consumer_resume(
    env: Env,
    consumer: ResourceArc<ConsumerRef>,
    from: Term,
) -> NifResult<Atom> {
    let consumer = consumer.get_resource()?;

    send_async_nif_result_with_from(env, from, async move {
        consumer
            .resume()
            .await
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif(name = "consumer_set_preferred_layers_async")]
pub fn consumer_set_preferred_layers(
    env: Env,
    consumer: ResourceArc<ConsumerRef>,
    layer: JsonSerdeWrap<ConsumerLayers>,
    from: Term,
) -> NifResult<Atom> {
    let consumer = consumer.get_resource()?;

    send_async_nif_result_with_from(env, from, async move {
        consumer
            .set_preferred_layers(*layer)
            .await
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif(name = "consumer_set_priority_async")]
pub fn consumer_set_priority(
    env: Env,
    consumer: ResourceArc<ConsumerRef>,
    priority: u8,
    from: Term,
) -> NifResult<Atom> {
    let consumer = consumer.get_resource()?;

    send_async_nif_result_with_from(env, from, async move {
        consumer
            .set_priority(priority)
            .await
            .map_err(|error| format!("{}", error))
    })
}
#[rustler::nif(name = "consumer_unset_priority_async")]
pub fn consumer_unset_priority(
    env: Env,
    consumer: ResourceArc<ConsumerRef>,
    from: Term,
) -> NifResult<Atom> {
    let consumer = consumer.get_resource()?;

    send_async_nif_result_with_from(env, from, async move {
        consumer
            .unset_priority()
            .await
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif(name = "consumer_request_key_frame_async")]
pub fn consumer_request_key_frame(
    env: Env,
    consumer: ResourceArc<ConsumerRef>,
    from: Term,
) -> NifResult<Atom> {
    let consumer = consumer.get_resource()?;

    send_async_nif_result_with_from(env, from, async move {
        consumer
            .request_key_frame()
            .await
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif(name = "consumer_dump_async")]
pub fn consumer_dump(env: Env, consumer: ResourceArc<ConsumerRef>, from: Term) -> NifResult<Atom> {
    let consumer = consumer.get_resource()?;

    send_async_nif_result_with_from(env, from, async move {
        consumer
            .dump()
            .await
            .map(JsonSerdeWrap::new)
            .map_err(|error| format!("{}", error))
    })
}

#[rustler::nif]
pub fn consumer_event(
    consumer: ResourceArc<ConsumerRef>,
    pid: rustler::LocalPid,
    event_types: Vec<Atom>,
) -> NifResult<(Atom,)> {
    let consumer = consumer.get_resource()?;

    if event_types.contains(&atoms::on_close()) {
        crate::reg_callback!(pid, consumer, on_close);
    }
    if event_types.contains(&atoms::on_pause()) {
        crate::reg_callback!(pid, consumer, on_pause);
    }
    if event_types.contains(&atoms::on_resume()) {
        crate::reg_callback!(pid, consumer, on_resume);
    }
    if event_types.contains(&atoms::on_producer_pause()) {
        crate::reg_callback!(pid, consumer, on_producer_pause);
    }
    if event_types.contains(&atoms::on_producer_resume()) {
        crate::reg_callback!(pid, consumer, on_producer_resume);
    }

    if event_types.contains(&atoms::on_producer_close()) {
        crate::reg_callback!(pid, consumer, on_producer_close);
    }

    if event_types.contains(&atoms::on_transport_close()) {
        crate::reg_callback!(pid, consumer, on_transport_close);
    }

    if event_types.contains(&atoms::on_layers_change()) {
        consumer
            .on_layers_change(move |layer| {
                send_msg_from_other_thread(
                    pid,
                    (
                        atoms::nif_internal_event(),
                        atoms::on_layers_change(),
                        JsonSerdeWrap::new(*layer),
                    ),
                );
            })
            .detach();
    }
    if event_types.contains(&atoms::on_score()) {
        //let pid = pid.clone();
        consumer
            .on_score(move |score| {
                send_msg_from_other_thread(
                    pid,
                    (
                        atoms::nif_internal_event(),
                        atoms::on_score(),
                        JsonSerdeWrap::new(score.clone()),
                    ),
                );
            })
            .detach();
    }

    Ok((atoms::ok(),))
}

#[derive(NifStruct)]
#[module = "Mediasoup.Consumer.Options"]
pub struct ConsumerOptionsStruct {
    producer_id: JsonSerdeWrap<ProducerId>,
    rtp_capabilities: JsonSerdeWrap<RtpCapabilities>,
    paused: Option<bool>,
    enable_rtx: Option<bool>,
    ignore_dtx: Option<bool>,
    preferred_layers: JsonSerdeWrap<Option<ConsumerLayers>>,
    pipe: Option<bool>,
    mid: Option<String>,
}

impl ConsumerOptionsStruct {
    pub fn to_option(&self) -> ConsumerOptions {
        let mut option = ConsumerOptions::new(*self.producer_id, self.rtp_capabilities.clone());
        if let Some(paused) = self.paused {
            option.paused = paused;
        }
        option.enable_rtx = self.enable_rtx;
        if let Some(ignore_dtx) = self.ignore_dtx {
            option.ignore_dtx = ignore_dtx;
        }
        option.preferred_layers = *self.preferred_layers;
        if let Some(pipe) = self.pipe {
            option.pipe = pipe;
        }
        option.mid.clone_from(&self.mid);
        option
    }
}

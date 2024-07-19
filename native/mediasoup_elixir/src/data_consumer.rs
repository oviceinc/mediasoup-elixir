use crate::json_serde::JsonSerdeWrap;
use crate::{atoms, DisposableResourceWrapper};
use mediasoup::data_consumer::DataConsumerType;
use mediasoup::data_producer::DataProducerId;
use mediasoup::prelude::{DataConsumer, DataConsumerId, DataConsumerOptions};
use mediasoup::sctp_parameters::SctpStreamParameters;
use rustler::{Atom, NifResult, NifStruct, ResourceArc};

pub type DataConsumerRef = DisposableResourceWrapper<DataConsumer>;

#[rustler::resource_impl]
impl rustler::Resource for DataConsumerRef {}

#[rustler::nif]
pub fn data_consumer_id(
    data_consumer: ResourceArc<DataConsumerRef>,
) -> NifResult<JsonSerdeWrap<DataConsumerId>> {
    let data_consumer = data_consumer.get_resource()?;
    Ok(data_consumer.id().into())
}

#[rustler::nif]
pub fn data_consumer_producer_id(
    data_consumer: ResourceArc<DataConsumerRef>,
) -> NifResult<JsonSerdeWrap<DataProducerId>> {
    let data_consumer = data_consumer.get_resource()?;
    Ok(data_consumer.data_producer_id().into())
}

#[rustler::nif]
pub fn data_consumer_type(
    data_consumer: ResourceArc<DataConsumerRef>,
) -> NifResult<JsonSerdeWrap<DataConsumerType>> {
    let data_consumer = data_consumer.get_resource()?;
    Ok(data_consumer.r#type().into())
}

#[rustler::nif]
pub fn data_consumer_sctp_stream_parameters(
    data_consumer: ResourceArc<DataConsumerRef>,
) -> NifResult<JsonSerdeWrap<Option<SctpStreamParameters>>> {
    let data_consumer = data_consumer.get_resource()?;
    Ok(data_consumer.sctp_stream_parameters().into())
}

#[rustler::nif]
pub fn data_consumer_label(data_consumer: ResourceArc<DataConsumerRef>) -> NifResult<String> {
    let data_consumer = data_consumer.get_resource()?;
    Ok(data_consumer.label().into())
}

#[rustler::nif]
pub fn data_consumer_protocol(data_consumer: ResourceArc<DataConsumerRef>) -> NifResult<String> {
    let data_consumer = data_consumer.get_resource()?;
    Ok(data_consumer.protocol().into())
}

#[rustler::nif]
pub fn data_consumer_close(data_consumer: ResourceArc<DataConsumerRef>) -> NifResult<(Atom,)> {
    data_consumer.close();
    Ok((atoms::ok(),))
}

#[rustler::nif]
pub fn data_consumer_closed(data_consumer: ResourceArc<DataConsumerRef>) -> NifResult<bool> {
    match data_consumer.get_resource() {
        Ok(data_consumer) => Ok(data_consumer.closed()),
        Err(_) => Ok(true),
    }
}

#[rustler::nif]
pub fn data_consumer_event(
    data_consumer: ResourceArc<DataConsumerRef>,
    pid: rustler::LocalPid,
    event_types: Vec<Atom>,
) -> NifResult<(Atom,)> {
    let data_consumer = data_consumer.get_resource()?;

    if event_types.contains(&atoms::on_close()) {
        crate::reg_callback!(pid, data_consumer, on_close);
    }

    Ok((atoms::ok(),))
}

#[derive(NifStruct)]
#[module = "Mediasoup.DataConsumer.Options"]
pub struct DataConsumerOptionsStruct {
    data_producer_id: JsonSerdeWrap<DataProducerId>,
}

impl DataConsumerOptionsStruct {
    pub fn to_option(&self) -> DataConsumerOptions {
        DataConsumerOptions::new_sctp(*self.data_producer_id)
    }
}

use crate::atoms;
use crate::{json_serde::JsonSerdeWrap, DataProducerRef};
use mediasoup::data_producer::{DataProducerOptions, DataProducerType};
use mediasoup::prelude::DataProducerId;
use mediasoup::sctp_parameters::SctpStreamParameters;
use rustler::{Atom, NifResult, NifStruct, ResourceArc};

#[rustler::nif]
pub fn data_producer_id(
    data_producer: ResourceArc<DataProducerRef>,
) -> NifResult<JsonSerdeWrap<DataProducerId>> {
    let data_producer = data_producer.get_resource()?;
    Ok(data_producer.id().into())
}

#[rustler::nif]
pub fn data_producer_type(
    data_producer: ResourceArc<DataProducerRef>,
) -> NifResult<JsonSerdeWrap<DataProducerType>> {
    let data_producer = data_producer.get_resource()?;
    Ok(data_producer.r#type().into())
}

#[rustler::nif]
pub fn data_producer_sctp_stream_parameters(
    data_producer: ResourceArc<DataProducerRef>,
) -> NifResult<JsonSerdeWrap<Option<SctpStreamParameters>>> {
    let data_producer = data_producer.get_resource()?;
    Ok(data_producer.sctp_stream_parameters().into())
}

#[rustler::nif]
pub fn data_producer_close(data_producer: ResourceArc<DataProducerRef>) -> NifResult<(Atom,)> {
    data_producer.close();
    Ok((atoms::ok(),))
}

#[rustler::nif]
pub fn data_producer_closed(data_producer: ResourceArc<DataProducerRef>) -> NifResult<bool> {
    match data_producer.get_resource() {
        Ok(data_producer) => Ok(data_producer.closed()),
        Err(_) => Ok(true),
    }
}

#[rustler::nif]
pub fn data_producer_event(
    data_producer: ResourceArc<DataProducerRef>,
    pid: rustler::LocalPid,
    event_types: Vec<Atom>,
) -> NifResult<(rustler::Atom,)> {
    let data_producer = data_producer.get_resource()?;

    if event_types.contains(&atoms::on_close()) {
        crate::reg_callback!(pid, data_producer, on_close);
    }

    Ok((atoms::ok(),))
}

#[derive(NifStruct)]
#[module = "Mediasoup.DataProducer.Options"]
pub struct DataProducerOptionsStruct {
    pub sctp_stream_parameters: Option<JsonSerdeWrap<SctpStreamParameters>>,
}

impl DataProducerOptionsStruct {
    pub fn to_option(&self) -> DataProducerOptions {
        match &self.sctp_stream_parameters {
            Some(sctp_stream_parameters) => DataProducerOptions::new_sctp(**sctp_stream_parameters),
            None => DataProducerOptions::new_direct(),
        }
    }
}

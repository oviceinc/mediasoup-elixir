use mediasoup::types::sctp_parameters::NumSctpStreams;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug, PartialEq, Eq)]
pub struct SerNumSctpStreams {
    #[serde(rename = "OS")]
    pub os: u16,
    #[serde(rename = "MIS")]
    pub mis: u16,
}
impl SerNumSctpStreams {
    pub fn as_streams(&self) -> NumSctpStreams {
        NumSctpStreams {
            os: self.os,
            mis: self.mis,
        }
    }
}

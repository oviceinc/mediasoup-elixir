//! NIF for mediasoup's get_supported_rtp_capabilities.
//! Returns the RTP capabilities supported by the mediasoup library.

use crate::json_serde::JsonSerdeWrap;
use mediasoup::rtp_parameters::RtpCapabilities;
use mediasoup::supported_rtp_capabilities;
use rustler::NifResult;

#[rustler::nif]
pub fn get_supported_rtp_capabilities() -> NifResult<JsonSerdeWrap<RtpCapabilities>> {
    let capabilities = supported_rtp_capabilities::get_supported_rtp_capabilities();
    Ok(JsonSerdeWrap::new(capabilities))
}

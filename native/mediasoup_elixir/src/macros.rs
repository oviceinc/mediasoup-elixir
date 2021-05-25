#[doc(hidden)]
#[macro_export]
macro_rules! define_rustler_serde_by_json {
    (
        $struct_name: ty
    ) => {
        impl<'a> rustler::Encoder for $struct_name {
            fn encode<'b>(&self, env: Env<'b>) -> Term<'b> {
                return crate::json_serde::json_encode(self, env);
            }
        }
        impl<'a> rustler::Decoder<'a> for $struct_name {
            fn decode(term: Term<'a>) -> rustler::NifResult<Self> {
                return crate::json_serde::json_decode(term);
            }
        }
    };
}

#[doc(hidden)]
#[macro_export]
macro_rules! reg_callback {
    ($pid: ident, $value: ident, $event_name: ident) => {{
        let pid = $pid.clone();
        $value
            .$event_name(move || {
                let pid = pid.clone();
                crate::send_msg_from_other_thread(pid, (atoms::$event_name(),))
            })
            .detach();
    }};
}

#[doc(hidden)]
#[macro_export]
macro_rules! reg_callback_json_param {
    ($pid: ident, $value: ident, $event_name: ident) => {{
        let pid = $pid.clone();
        $value
            .$event_name(move |arg| {
                let pid = pid.clone();
                crate::send_msg_from_other_thread(
                    pid,
                    (
                        atoms::$event_name(),
                        crate::json_serde::JsonSerdeWrap::new(arg),
                    ),
                )
            })
            .detach();
    }};
}

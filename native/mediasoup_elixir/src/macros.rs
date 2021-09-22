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

#[doc(hidden)]
#[macro_export]
macro_rules! reg_callback_json_clone_param {
    ($pid: ident, $value: ident, $event_name: ident) => {{
        let pid = $pid.clone();
        $value
            .$event_name(move |arg| {
                let pid = pid.clone();
                crate::send_msg_from_other_thread(
                    pid,
                    (
                        atoms::$event_name(),
                        crate::json_serde::JsonSerdeWrap::new(arg.clone()),
                    ),
                )
            })
            .detach();
    }};
}

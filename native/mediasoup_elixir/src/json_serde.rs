use crate::atoms;
use rustler::types::atom;
use rustler::types::map::MapIterator;
use rustler::types::tuple::get_tuple;
use rustler::{Encoder, Env, NifResult, Term, TermType};
use serde_json::{Map, Number, Value};

// Values are converted with the same shapes as a JSON round trip (string keyed
// maps, unit variants as strings, ...) without formatting and parsing JSON text.
// Encoding writes terms directly (see term_ser), decoding goes through serde_json::Value.

fn key_to_string(term: Term) -> NifResult<String> {
    match term.get_type() {
        TermType::Atom => term.atom_to_string(),
        TermType::Binary => Ok(term.decode::<&str>()?.to_owned()),
        TermType::Integer => match term.decode::<u64>() {
            Ok(u) => Ok(u.to_string()),
            Err(_) => Ok(term.decode::<i64>()?.to_string()),
        },
        _ => Err(rustler::Error::BadArg),
    }
}

fn term_to_value(term: Term) -> NifResult<Value> {
    match term.get_type() {
        TermType::Atom => {
            if term == atom::nil().to_term(term.get_env()) {
                Ok(Value::Null)
            } else if let Ok(b) = term.decode::<bool>() {
                Ok(Value::Bool(b))
            } else {
                Ok(Value::String(term.atom_to_string()?))
            }
        }
        TermType::Integer => match term.decode::<u64>() {
            Ok(u) => Ok(Value::Number(u.into())),
            Err(_) => Ok(Value::Number(term.decode::<i64>()?.into())),
        },
        TermType::Float => Number::from_f64(term.decode::<f64>()?)
            .map(Value::Number)
            .ok_or(rustler::Error::BadArg),
        TermType::Binary => Ok(Value::String(term.decode::<&str>()?.to_owned())),
        TermType::List => term
            .decode::<rustler::ListIterator>()?
            .map(term_to_value)
            .collect::<NifResult<Vec<Value>>>()
            .map(Value::Array),
        TermType::Tuple => get_tuple(term)?
            .into_iter()
            .map(term_to_value)
            .collect::<NifResult<Vec<Value>>>()
            .map(Value::Array),
        TermType::Map => {
            let struct_key = atoms::__struct__().to_term(term.get_env());
            let mut object = Map::new();
            for (k, v) in MapIterator::new(term).ok_or(rustler::Error::BadArg)? {
                if k == struct_key {
                    continue;
                }
                object.insert(key_to_string(k)?, term_to_value(v)?);
            }
            Ok(Value::Object(object))
        }
        _ => Err(rustler::Error::BadArg),
    }
}

pub fn json_encode<'a, T>(v: &T, env: Env<'a>) -> Term<'a>
where
    T: serde::Serialize,
{
    match crate::term_ser::to_term(env, v) {
        Ok(term) => term,
        Err(err) => err.to_string().encode(env),
    }
}
pub fn json_decode<'de, 'a: 'de, T>(term: Term<'a>) -> NifResult<T>
where
    T: serde::de::DeserializeOwned + serde::Serialize + 'a,
{
    let value = term_to_value(term)?;
    serde_json::from_value(value).map_err(|_| rustler::Error::BadArg)
}

#[derive(serde::Serialize, serde::Deserialize)]
pub struct JsonSerdeWrap<T>(T);

impl<T> JsonSerdeWrap<T> {
    pub fn new(value: T) -> Self {
        Self(value)
    }
}

impl<'de, 'a: 'de, T> rustler::Encoder for JsonSerdeWrap<T>
where
    T: serde::Serialize,
{
    fn encode<'b>(&self, env: Env<'b>) -> Term<'b> {
        json_encode(&self.0, env)
    }
}
impl<'a, T> rustler::Decoder<'a> for JsonSerdeWrap<T>
where
    T: serde::de::DeserializeOwned + serde::Serialize + 'a,
{
    fn decode(term: Term<'a>) -> rustler::NifResult<Self> {
        let v: T = json_decode(term)?;
        Ok(Self::new(v))
    }
}
impl<T> std::ops::Deref for JsonSerdeWrap<T> {
    type Target = T;
    fn deref(&self) -> &T {
        &self.0
    }
}

impl<T> From<T> for JsonSerdeWrap<T> {
    fn from(v: T) -> Self {
        Self::new(v)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde::{Deserialize, Serialize};

    #[derive(Serialize, Deserialize)]
    struct A {
        v: String,
    }

    #[test]
    fn serialize_with_flatten() {
        let value = A {
            v: String::from("value"),
        };
        let wraped = JsonSerdeWrap::new(value);
        let jsonstring = serde_json::to_string(&wraped).unwrap();
        assert_eq!(String::from("{\"v\":\"value\"}"), jsonstring);

        let p: A = serde_json::from_str(&jsonstring).unwrap();
        assert_eq!("value", p.v);

        let value = String::from("value");
        let wraped = JsonSerdeWrap::new(value);
        let jsonstring = serde_json::to_string(&wraped).unwrap();
        assert_eq!(String::from("\"value\""), jsonstring);

        let p: String = serde_json::from_str(&jsonstring).unwrap();

        assert_eq!("value", p);
    }
}

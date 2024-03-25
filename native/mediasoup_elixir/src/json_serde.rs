use crate::atoms;
use rustler::{Env, NifResult, Term};

fn to_json(term: Term) -> Result<std::vec::Vec<u8>, serde_json::Error> {
    let de = rustler::serde::Deserializer::from(term);
    let mut writer = Vec::with_capacity(128);
    let mut se = serde_json::Serializer::new(&mut writer);
    serde_transcode::transcode(de, &mut se)?;

    Ok(writer)
}
fn from_json(env: Env, vec: Vec<u8>) -> NifResult<Term> {
    let mut de = serde_json::Deserializer::from_slice(&vec);
    let se = rustler::serde::Serializer::from(env);
    serde_transcode::transcode(&mut de, se).map_err(|err| err.into())
}

pub fn json_encode<'a, T>(v: &T, env: Env<'a>) -> Term<'a>
where
    T: serde::Serialize,
{
    let json = match serde_json::to_vec(v) {
        Ok(json) => json,
        Err(err) => return rustler::Encoder::encode(&err.to_string(), env),
    };
    return match from_json(env, json) {
        Ok(term) => term,
        Err(error) => rustler::Encoder::encode(&(atoms::error(), format!("{:?}", error)), env), // TODO:
    };
}
pub fn json_decode<'de, 'a: 'de, T>(term: Term<'a>) -> NifResult<T>
where
    T: serde::de::DeserializeOwned + serde::Serialize + 'a,
{
    let json = to_json(term).map_err(|_| rustler::Error::BadArg)?;
    serde_json::from_slice(&json).map_err(|_| rustler::Error::BadArg)
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

use rustler::{Env, NifResult, Term};

fn to_json<'a>(term: Term<'a>) -> Result<std::vec::Vec<u8>, serde_json::Error> {
    let de = serde_rustler::Deserializer::from(term);
    let mut writer = Vec::with_capacity(128);
    let mut se = serde_json::Serializer::new(&mut writer);
    serde_transcode::transcode(de, &mut se)?;

    return Ok(writer);
}
fn from_json<'a>(env: Env<'a>, mut vec: Vec<u8>) -> NifResult<Term<'a>> {
    let mut de = serde_json::Deserializer::from_slice(&mut vec);
    let se = serde_rustler::Serializer::from(env);
    return serde_transcode::transcode(&mut de, se).map_err(|err| err.into());
}

pub fn json_encode<'de, 'a: 'de, T>(v: &T, env: Env<'a>) -> Term<'a>
where
    T: serde::Deserialize<'de> + serde::Serialize + 'a,
{
    JsonEncoder::encode(v, env)
}

pub trait JsonDecoder<'a>: Sized + 'a {
    fn decode(term: Term<'a>) -> NifResult<Self>;
}

pub trait JsonEncoder: Sized {
    fn encode<'a>(&self, env: Env<'a>) -> Term<'a>;
}

impl<'a, T> JsonDecoder<'a> for T
where
    T: serde::de::DeserializeOwned + serde::Serialize + 'a,
{
    fn decode(term: Term<'a>) -> NifResult<T> {
        let json = to_json(term).map_err(|_| rustler::Error::BadArg)?;
        return serde_json::from_slice(&json).map_err(|_| rustler::Error::BadArg);
    }
}

impl<'de, T> JsonEncoder for T
where
    T: serde::Serialize,
{
    fn encode<'a>(&self, env: Env<'a>) -> rustler::Term<'a> {
        let json = match serde_json::to_vec(self) {
            Ok(json) => json,
            Err(err) => return rustler::Encoder::encode(&err.to_string(), env),
        };
        return match from_json(env, json) {
            Ok(term) => term,
            Err(_) => rustler::Encoder::encode("err", env), // TODO:
        };
    }
}

pub struct JsonSerdeWrap<T>(T);

impl<T> JsonSerdeWrap<T> {
    pub fn new(value: T) -> Self {
        return Self(value);
    }
}

impl<'de, 'a: 'de, T> rustler::Encoder for JsonSerdeWrap<T>
where
    T: serde::Serialize,
{
    fn encode<'b>(&self, env: Env<'b>) -> Term<'b> {
        return JsonEncoder::encode(&self.0, env);
    }
}
impl<'a, T> rustler::Decoder<'a> for JsonSerdeWrap<T>
where
    T: serde::de::DeserializeOwned + serde::Serialize + 'a,
{
    fn decode(term: Term<'a>) -> rustler::NifResult<Self> {
        let v: T = JsonDecoder::decode(term)?;
        return Ok(Self(v));
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
        Self(v)
    }
}

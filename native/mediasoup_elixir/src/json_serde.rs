use rustler::{Env, NifResult, Term};

fn to_json(term: Term) -> Result<std::vec::Vec<u8>, serde_json::Error> {
    let de = serde_rustler::Deserializer::from(term);
    let mut writer = Vec::with_capacity(128);
    let mut se = serde_json::Serializer::new(&mut writer);
    serde_transcode::transcode(de, &mut se)?;

    Ok(writer)
}
fn from_json(env: Env, vec: Vec<u8>) -> NifResult<Term> {
    let mut de = serde_json::Deserializer::from_slice(&vec);
    let se = serde_rustler::Serializer::from(env);
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
        Err(_) => rustler::Encoder::encode("err", env), // TODO:
    };
}
pub fn json_decode<'de, 'a: 'de, T>(term: Term<'a>) -> NifResult<T>
where
    T: serde::de::DeserializeOwned + serde::Serialize + 'a,
{
    let json = to_json(term).map_err(|_| rustler::Error::BadArg)?;
    serde_json::from_slice(&json).map_err(|_| rustler::Error::BadArg)
}

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
        Ok(Self(v))
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

// Serializes Rust values directly into terms with the same shapes as
// `serde_json::to_value` (maps with string keys, unit variants as strings,
// externally tagged enums, ...), without an intermediate JSON text or Value.

use rustler::types::atom;
use rustler::{Encoder, Env, Term};
use serde::ser::{self, Serialize};
use std::fmt::Display;

#[derive(Debug)]
pub struct Error(String);

impl Display for Error {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(&self.0)
    }
}
impl std::error::Error for Error {}
impl ser::Error for Error {
    fn custom<T: Display>(msg: T) -> Self {
        Error(msg.to_string())
    }
}

type Result<T> = std::result::Result<T, Error>;

pub fn to_term<'a, T: ?Sized + Serialize>(env: Env<'a>, value: &T) -> Result<Term<'a>> {
    value.serialize(TermSerializer { env })
}

#[derive(Clone, Copy)]
pub struct TermSerializer<'a> {
    env: Env<'a>,
}

fn make_map<'a>(env: Env<'a>, keys: &[Term<'a>], values: &[Term<'a>]) -> Term<'a> {
    Term::map_from_term_arrays(env, keys, values).unwrap_or_else(|_| {
        // duplicated keys (e.g. with #[serde(flatten)]): the last one wins, as in serde_json.
        keys.iter()
            .zip(values)
            .fold(Term::map_new(env), |map, (k, v)| {
                map.map_put(*k, *v).unwrap_or(map)
            })
    })
}

fn tagged<'a>(env: Env<'a>, variant: &str, value: Term<'a>) -> Term<'a> {
    make_map(env, &[variant.encode(env)], &[value])
}

impl<'a> ser::Serializer for TermSerializer<'a> {
    type Ok = Term<'a>;
    type Error = Error;
    type SerializeSeq = SeqSerializer<'a>;
    type SerializeTuple = SeqSerializer<'a>;
    type SerializeTupleStruct = SeqSerializer<'a>;
    type SerializeTupleVariant = SeqSerializer<'a>;
    type SerializeMap = MapSerializer<'a>;
    type SerializeStruct = MapSerializer<'a>;
    type SerializeStructVariant = MapSerializer<'a>;

    fn serialize_bool(self, v: bool) -> Result<Term<'a>> {
        Ok(v.encode(self.env))
    }
    fn serialize_i8(self, v: i8) -> Result<Term<'a>> {
        self.serialize_i64(v as i64)
    }
    fn serialize_i16(self, v: i16) -> Result<Term<'a>> {
        self.serialize_i64(v as i64)
    }
    fn serialize_i32(self, v: i32) -> Result<Term<'a>> {
        self.serialize_i64(v as i64)
    }
    fn serialize_i64(self, v: i64) -> Result<Term<'a>> {
        Ok(v.encode(self.env))
    }
    fn serialize_i128(self, v: i128) -> Result<Term<'a>> {
        if let Ok(v) = u64::try_from(v) {
            self.serialize_u64(v)
        } else if let Ok(v) = i64::try_from(v) {
            self.serialize_i64(v)
        } else {
            Err(ser::Error::custom("number out of range"))
        }
    }
    fn serialize_u8(self, v: u8) -> Result<Term<'a>> {
        self.serialize_u64(v as u64)
    }
    fn serialize_u16(self, v: u16) -> Result<Term<'a>> {
        self.serialize_u64(v as u64)
    }
    fn serialize_u32(self, v: u32) -> Result<Term<'a>> {
        self.serialize_u64(v as u64)
    }
    fn serialize_u64(self, v: u64) -> Result<Term<'a>> {
        Ok(v.encode(self.env))
    }
    fn serialize_u128(self, v: u128) -> Result<Term<'a>> {
        match u64::try_from(v) {
            Ok(v) => self.serialize_u64(v),
            Err(_) => Err(ser::Error::custom("number out of range")),
        }
    }
    fn serialize_f32(self, v: f32) -> Result<Term<'a>> {
        // same as serde_json: f32 -> f64 through its shortest decimal representation
        if v.is_finite() {
            self.serialize_f64(v.to_string().parse::<f64>().unwrap_or(v as f64))
        } else {
            self.serialize_unit()
        }
    }
    fn serialize_f64(self, v: f64) -> Result<Term<'a>> {
        if v.is_finite() {
            Ok(v.encode(self.env))
        } else {
            self.serialize_unit()
        }
    }
    fn serialize_char(self, v: char) -> Result<Term<'a>> {
        self.serialize_str(v.encode_utf8(&mut [0u8; 4]))
    }
    fn serialize_str(self, v: &str) -> Result<Term<'a>> {
        Ok(v.encode(self.env))
    }
    fn serialize_bytes(self, v: &[u8]) -> Result<Term<'a>> {
        Ok(v.iter()
            .map(|b| b.encode(self.env))
            .collect::<Vec<Term<'a>>>()
            .encode(self.env))
    }
    fn serialize_none(self) -> Result<Term<'a>> {
        self.serialize_unit()
    }
    fn serialize_some<T: ?Sized + Serialize>(self, value: &T) -> Result<Term<'a>> {
        value.serialize(self)
    }
    fn serialize_unit(self) -> Result<Term<'a>> {
        Ok(atom::nil().encode(self.env))
    }
    fn serialize_unit_struct(self, _name: &'static str) -> Result<Term<'a>> {
        self.serialize_unit()
    }
    fn serialize_unit_variant(
        self,
        _name: &'static str,
        _variant_index: u32,
        variant: &'static str,
    ) -> Result<Term<'a>> {
        self.serialize_str(variant)
    }
    fn serialize_newtype_struct<T: ?Sized + Serialize>(
        self,
        _name: &'static str,
        value: &T,
    ) -> Result<Term<'a>> {
        value.serialize(self)
    }
    fn serialize_newtype_variant<T: ?Sized + Serialize>(
        self,
        _name: &'static str,
        _variant_index: u32,
        variant: &'static str,
        value: &T,
    ) -> Result<Term<'a>> {
        Ok(tagged(self.env, variant, value.serialize(self)?))
    }
    fn serialize_seq(self, len: Option<usize>) -> Result<SeqSerializer<'a>> {
        Ok(SeqSerializer {
            env: self.env,
            variant: None,
            items: Vec::with_capacity(len.unwrap_or(0)),
        })
    }
    fn serialize_tuple(self, len: usize) -> Result<SeqSerializer<'a>> {
        self.serialize_seq(Some(len))
    }
    fn serialize_tuple_struct(self, _name: &'static str, len: usize) -> Result<SeqSerializer<'a>> {
        self.serialize_seq(Some(len))
    }
    fn serialize_tuple_variant(
        self,
        _name: &'static str,
        _variant_index: u32,
        variant: &'static str,
        len: usize,
    ) -> Result<SeqSerializer<'a>> {
        Ok(SeqSerializer {
            env: self.env,
            variant: Some(variant),
            items: Vec::with_capacity(len),
        })
    }
    fn serialize_map(self, len: Option<usize>) -> Result<MapSerializer<'a>> {
        Ok(MapSerializer {
            env: self.env,
            variant: None,
            keys: Vec::with_capacity(len.unwrap_or(0)),
            values: Vec::with_capacity(len.unwrap_or(0)),
        })
    }
    fn serialize_struct(self, _name: &'static str, len: usize) -> Result<MapSerializer<'a>> {
        self.serialize_map(Some(len))
    }
    fn serialize_struct_variant(
        self,
        _name: &'static str,
        _variant_index: u32,
        variant: &'static str,
        len: usize,
    ) -> Result<MapSerializer<'a>> {
        Ok(MapSerializer {
            env: self.env,
            variant: Some(variant),
            keys: Vec::with_capacity(len),
            values: Vec::with_capacity(len),
        })
    }
}

pub struct SeqSerializer<'a> {
    env: Env<'a>,
    variant: Option<&'static str>,
    items: Vec<Term<'a>>,
}

impl<'a> SeqSerializer<'a> {
    fn push<T: ?Sized + Serialize>(&mut self, value: &T) -> Result<()> {
        self.items
            .push(value.serialize(TermSerializer { env: self.env })?);
        Ok(())
    }
    fn finish(self) -> Result<Term<'a>> {
        let list = self.items.encode(self.env);
        Ok(match self.variant {
            Some(variant) => tagged(self.env, variant, list),
            None => list,
        })
    }
}

impl<'a> ser::SerializeSeq for SeqSerializer<'a> {
    type Ok = Term<'a>;
    type Error = Error;
    fn serialize_element<T: ?Sized + Serialize>(&mut self, value: &T) -> Result<()> {
        self.push(value)
    }
    fn end(self) -> Result<Term<'a>> {
        self.finish()
    }
}
impl<'a> ser::SerializeTuple for SeqSerializer<'a> {
    type Ok = Term<'a>;
    type Error = Error;
    fn serialize_element<T: ?Sized + Serialize>(&mut self, value: &T) -> Result<()> {
        self.push(value)
    }
    fn end(self) -> Result<Term<'a>> {
        self.finish()
    }
}
impl<'a> ser::SerializeTupleStruct for SeqSerializer<'a> {
    type Ok = Term<'a>;
    type Error = Error;
    fn serialize_field<T: ?Sized + Serialize>(&mut self, value: &T) -> Result<()> {
        self.push(value)
    }
    fn end(self) -> Result<Term<'a>> {
        self.finish()
    }
}
impl<'a> ser::SerializeTupleVariant for SeqSerializer<'a> {
    type Ok = Term<'a>;
    type Error = Error;
    fn serialize_field<T: ?Sized + Serialize>(&mut self, value: &T) -> Result<()> {
        self.push(value)
    }
    fn end(self) -> Result<Term<'a>> {
        self.finish()
    }
}

pub struct MapSerializer<'a> {
    env: Env<'a>,
    variant: Option<&'static str>,
    keys: Vec<Term<'a>>,
    values: Vec<Term<'a>>,
}

impl<'a> MapSerializer<'a> {
    fn finish(self) -> Result<Term<'a>> {
        if self.keys.len() != self.values.len() {
            return Err(ser::Error::custom("map key without value"));
        }
        let map = make_map(self.env, &self.keys, &self.values);
        Ok(match self.variant {
            Some(variant) => tagged(self.env, variant, map),
            None => map,
        })
    }
}

impl<'a> ser::SerializeMap for MapSerializer<'a> {
    type Ok = Term<'a>;
    type Error = Error;
    fn serialize_key<T: ?Sized + Serialize>(&mut self, key: &T) -> Result<()> {
        self.keys
            .push(key.serialize(KeySerializer { env: self.env })?);
        Ok(())
    }
    fn serialize_value<T: ?Sized + Serialize>(&mut self, value: &T) -> Result<()> {
        self.values
            .push(value.serialize(TermSerializer { env: self.env })?);
        Ok(())
    }
    fn end(self) -> Result<Term<'a>> {
        self.finish()
    }
}
impl<'a> ser::SerializeStruct for MapSerializer<'a> {
    type Ok = Term<'a>;
    type Error = Error;
    fn serialize_field<T: ?Sized + Serialize>(
        &mut self,
        key: &'static str,
        value: &T,
    ) -> Result<()> {
        self.keys.push(key.encode(self.env));
        self.values
            .push(value.serialize(TermSerializer { env: self.env })?);
        Ok(())
    }
    fn end(self) -> Result<Term<'a>> {
        self.finish()
    }
}
impl<'a> ser::SerializeStructVariant for MapSerializer<'a> {
    type Ok = Term<'a>;
    type Error = Error;
    fn serialize_field<T: ?Sized + Serialize>(
        &mut self,
        key: &'static str,
        value: &T,
    ) -> Result<()> {
        ser::SerializeStruct::serialize_field(self, key, value)
    }
    fn end(self) -> Result<Term<'a>> {
        self.finish()
    }
}

/// Map keys are always strings, following serde_json's rules.
struct KeySerializer<'a> {
    env: Env<'a>,
}

fn key_must_be_a_string() -> Error {
    ser::Error::custom("key must be a string")
}

impl<'a> KeySerializer<'a> {
    fn display<T: Display>(self, v: T) -> Result<Term<'a>> {
        Ok(v.to_string().encode(self.env))
    }

    // Formats a key with serde_json itself (used for float keys).
    fn json_key<K: Serialize>(self, key: K) -> Result<Term<'a>> {
        struct One<K>(K);
        impl<K: Serialize> Serialize for One<K> {
            fn serialize<S: ser::Serializer>(&self, s: S) -> std::result::Result<S::Ok, S::Error> {
                s.collect_map(std::iter::once((&self.0, ())))
            }
        }
        match serde_json::to_value(One(key)).map_err(ser::Error::custom)? {
            serde_json::Value::Object(map) => match map.keys().next() {
                Some(k) => Ok(k.as_str().encode(self.env)),
                None => Err(key_must_be_a_string()),
            },
            _ => Err(key_must_be_a_string()),
        }
    }
}

impl<'a> ser::Serializer for KeySerializer<'a> {
    type Ok = Term<'a>;
    type Error = Error;
    type SerializeSeq = ser::Impossible<Term<'a>, Error>;
    type SerializeTuple = ser::Impossible<Term<'a>, Error>;
    type SerializeTupleStruct = ser::Impossible<Term<'a>, Error>;
    type SerializeTupleVariant = ser::Impossible<Term<'a>, Error>;
    type SerializeMap = ser::Impossible<Term<'a>, Error>;
    type SerializeStruct = ser::Impossible<Term<'a>, Error>;
    type SerializeStructVariant = ser::Impossible<Term<'a>, Error>;

    fn serialize_bool(self, v: bool) -> Result<Term<'a>> {
        self.display(v)
    }
    fn serialize_i8(self, v: i8) -> Result<Term<'a>> {
        self.display(v)
    }
    fn serialize_i16(self, v: i16) -> Result<Term<'a>> {
        self.display(v)
    }
    fn serialize_i32(self, v: i32) -> Result<Term<'a>> {
        self.display(v)
    }
    fn serialize_i64(self, v: i64) -> Result<Term<'a>> {
        self.display(v)
    }
    fn serialize_i128(self, v: i128) -> Result<Term<'a>> {
        self.display(v)
    }
    fn serialize_u8(self, v: u8) -> Result<Term<'a>> {
        self.display(v)
    }
    fn serialize_u16(self, v: u16) -> Result<Term<'a>> {
        self.display(v)
    }
    fn serialize_u32(self, v: u32) -> Result<Term<'a>> {
        self.display(v)
    }
    fn serialize_u64(self, v: u64) -> Result<Term<'a>> {
        self.display(v)
    }
    fn serialize_u128(self, v: u128) -> Result<Term<'a>> {
        self.display(v)
    }
    fn serialize_f32(self, v: f32) -> Result<Term<'a>> {
        self.json_key(v)
    }
    fn serialize_f64(self, v: f64) -> Result<Term<'a>> {
        self.json_key(v)
    }
    fn serialize_char(self, v: char) -> Result<Term<'a>> {
        self.display(v)
    }
    fn serialize_str(self, v: &str) -> Result<Term<'a>> {
        Ok(v.encode(self.env))
    }
    fn serialize_bytes(self, _v: &[u8]) -> Result<Term<'a>> {
        Err(key_must_be_a_string())
    }
    fn serialize_none(self) -> Result<Term<'a>> {
        Err(key_must_be_a_string())
    }
    fn serialize_some<T: ?Sized + Serialize>(self, _value: &T) -> Result<Term<'a>> {
        Err(key_must_be_a_string())
    }
    fn serialize_unit(self) -> Result<Term<'a>> {
        Err(key_must_be_a_string())
    }
    fn serialize_unit_struct(self, _name: &'static str) -> Result<Term<'a>> {
        Err(key_must_be_a_string())
    }
    fn serialize_unit_variant(
        self,
        _name: &'static str,
        _variant_index: u32,
        variant: &'static str,
    ) -> Result<Term<'a>> {
        self.serialize_str(variant)
    }
    fn serialize_newtype_struct<T: ?Sized + Serialize>(
        self,
        _name: &'static str,
        value: &T,
    ) -> Result<Term<'a>> {
        value.serialize(self)
    }
    fn serialize_newtype_variant<T: ?Sized + Serialize>(
        self,
        _name: &'static str,
        _variant_index: u32,
        _variant: &'static str,
        _value: &T,
    ) -> Result<Term<'a>> {
        Err(key_must_be_a_string())
    }
    fn serialize_seq(self, _len: Option<usize>) -> Result<Self::SerializeSeq> {
        Err(key_must_be_a_string())
    }
    fn serialize_tuple(self, _len: usize) -> Result<Self::SerializeTuple> {
        Err(key_must_be_a_string())
    }
    fn serialize_tuple_struct(
        self,
        _name: &'static str,
        _len: usize,
    ) -> Result<Self::SerializeTupleStruct> {
        Err(key_must_be_a_string())
    }
    fn serialize_tuple_variant(
        self,
        _name: &'static str,
        _variant_index: u32,
        _variant: &'static str,
        _len: usize,
    ) -> Result<Self::SerializeTupleVariant> {
        Err(key_must_be_a_string())
    }
    fn serialize_map(self, _len: Option<usize>) -> Result<Self::SerializeMap> {
        Err(key_must_be_a_string())
    }
    fn serialize_struct(self, _name: &'static str, _len: usize) -> Result<Self::SerializeStruct> {
        Err(key_must_be_a_string())
    }
    fn serialize_struct_variant(
        self,
        _name: &'static str,
        _variant_index: u32,
        _variant: &'static str,
        _len: usize,
    ) -> Result<Self::SerializeStructVariant> {
        Err(key_must_be_a_string())
    }
}

use rustler::{MapIterator, NifResult, Term};
use std::collections::HashMap;

pub trait TypeDecoder<'a>: Sized + 'a {
    fn decode(term: Term<'a>) -> NifResult<Self>;
}

impl<'a> TypeDecoder<'a> for HashMap<std::string::String, Term<'a>> {
    fn decode(term: Term) -> NifResult<HashMap<std::string::String, Term>> {
        let mapit: MapIterator = term.decode()?;
        let map: HashMap<std::string::String, Term> = mapit
            .filter_map(|(key, value)| {
                match key.decode::<String>().or_else(|_| key.atom_to_string()) {
                    Ok(k) => Some((k, value)),
                    Err(_) => None,
                }
            })
            .collect();
        return NifResult::Ok(map);
    }
}

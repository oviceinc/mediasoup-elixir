use rustler::{Env, Term};

pub trait TypeEncoder<'a>: Sized + 'a {
    fn encode(&self, env: Env<'a>) -> Term<'a>;
}

use crate::atoms;
use std::sync::Mutex;
pub struct DisposableResourceWrapper<T>(pub Mutex<Option<T>>);
impl<T> DisposableResourceWrapper<T> {
    pub fn new(value: T) -> Self {
        Self(Mutex::new(Some(value)))
    }
    pub fn close(&self) {
        if let Ok(mut v) = self.0.lock() {
            *v = None;
        }
    }
}
impl<T> DisposableResourceWrapper<T>
where
    T: Clone,
{
    fn read(
        &self,
    ) -> Result<Option<T>, std::sync::PoisonError<std::sync::MutexGuard<std::option::Option<T>>>>
    {
        match self.0.lock() {
            Ok(v) => Ok(v.clone()),
            Err(err) => Err(err),
        }
    }

    pub fn get_resource(&self) -> rustler::NifResult<T> {
        let resource = self
            .read()
            .map_err(|_error| rustler::Error::Term(Box::new(atoms::poison_error())))?
            .ok_or_else(|| rustler::Error::Term(Box::new(atoms::terminated())))?;
        Ok(resource)
    }
}

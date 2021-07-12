use crate::atoms;
use rustler::ResourceArc;
use std::sync::RwLock;
/*
pub struct ResourceWrapper<T>(T);
impl<T> ResourceWrapper<T> {
    pub fn new(value: T) -> Self {
        Self(value)
    }
}

impl<T> ResourceWrapper<T>
where
    ResourceWrapper<T>: rustler::resource::ResourceTypeProvider,
{
    pub fn resource(value: T) -> ResourceArc<Self> {
        ResourceArc::new(Self::new(value))
    }
}

impl<T> std::ops::Deref for ResourceWrapper<T> {
    type Target = T;
    fn deref(&self) -> &T {
        &self.0
    }
}*/

pub struct DisposableResourceWrapper<T>(pub RwLock<Option<T>>);
impl<T> DisposableResourceWrapper<T> {
    pub fn new(value: T) -> Self {
        Self(RwLock::new(Some(value)))
    }
    pub fn close(&self) {
        if let Ok(mut v) = self.0.write() {
            *v = None;
        }
    }
}
impl<T: Clone> DisposableResourceWrapper<T> {
    fn read(
        &self,
    ) -> Result<Option<T>, std::sync::PoisonError<std::sync::RwLockReadGuard<std::option::Option<T>>>>
    {
        match self.0.read() {
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

impl<T> DisposableResourceWrapper<T>
where
    DisposableResourceWrapper<T>: rustler::resource::ResourceTypeProvider,
{
    pub fn resource(value: T) -> ResourceArc<Self> {
        ResourceArc::new(Self::new(value))
    }
}

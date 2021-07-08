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
        *self.0.write().unwrap() = None;
    }
}
impl<T: Clone> DisposableResourceWrapper<T> {
    // TODO: avoid panic.
    pub fn unwrap(&self) -> Option<T> {
        self.0.read().unwrap().clone()
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

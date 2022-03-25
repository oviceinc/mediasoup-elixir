use async_executor::{Executor, Task};
use futures_lite::future;
use once_cell::sync::Lazy;
use std::future::Future;
use std::sync::Arc;

static EXECUTOR: Lazy<Arc<Executor<'static>>> = Lazy::new(|| {
    let executor = Arc::new(Executor::new());
    let thread_count = std::cmp::max(2, num_cpus::get());

    for _ in 0..thread_count {
        create_thread_for_executor(Arc::clone(&executor));
    }
    executor
});

pub fn executor() -> Arc<Executor<'static>> {
    EXECUTOR.clone()
}

pub fn spawn<T>(task: T) -> Task<()>
where
    T: Future<Output = ()> + Send + 'static,
{
    executor().spawn(task)
}

fn create_thread_for_executor(executor: Arc<Executor<'static>>) {
    let builder = std::thread::Builder::new().name("ex-mediasoup-task".into());
    let _ = builder.spawn(move || {
        let _ = future::block_on(executor.run(async {
            let future = future::pending();
            let () = future.await;
        }));
    });
}

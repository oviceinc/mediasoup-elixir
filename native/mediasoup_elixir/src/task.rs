use async_executor::{Executor, Task};
use futures_lite::future;
use mediasoup::worker_manager::WorkerManager;
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

static WORKER_MANAGER: Lazy<Arc<WorkerManager>> = Lazy::new(|| Arc::new(WorkerManager::new()));

pub fn worker_manager() -> Arc<WorkerManager> {
    WORKER_MANAGER.clone()
}
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
    let builder = std::thread::Builder::new().name("ex-mediasoup-worker".into());
    let _ = builder.spawn(move || {
        let _ = future::block_on(executor.run(async {
            let future = future::pending();
            let () = future.await;
        }));
    });
}

use async_executor::{Executor, Task};
use futures_lite::future;
use mediasoup::worker_manager::WorkerManager;
use std::future::Future;
use std::sync::{Arc, LazyLock};

static EXECUTOR: LazyLock<Arc<Executor<'static>>> = LazyLock::new(|| {
    let executor = Arc::new(Executor::new());
    let thread_count = thread_count();

    for _ in 0..thread_count {
        create_thread_for_executor(Arc::clone(&executor), "ex-mediasoup-task".into());
    }
    executor
});

static WORKER_MANAGER: LazyLock<Arc<WorkerManager>> = LazyLock::new(|| {
    let executor = Arc::new(Executor::new());
    let thread_count = thread_count();

    for _ in 0..thread_count {
        create_thread_for_executor(Arc::clone(&executor), "ex-mediasoup-wm".into());
    }

    Arc::new(WorkerManager::with_executor(executor))
});

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

fn thread_count() -> usize {
    std::thread::available_parallelism().map_or(2, |n| n.get().max(2))
}

fn create_thread_for_executor(executor: Arc<Executor<'static>>, name: String) {
    let builder = std::thread::Builder::new().name(name);
    let _ = builder.spawn(move || {
        future::block_on(executor.run(async {
            let future = future::pending();
            let () = future.await;
        }));
    });
}

# MediasoupElixir
 [Mediasoup](https://mediasoup.org/) port for Elixir

## Installation
### Requirement
  * [Rust](https://www.rust-lang.org/)
  * `make` and `c/c++ compilers` for build for mediasoup


## Process vs reference
MediasoupElixir has two types of structure, Process and reference.
They have an almost same interface, The only difference is how it create.

### Process
``` elixir
# create Worker process
{:ok, worker} = Mediasoup.Worker.start_link()
# router struct has pid property as process
{:ok, router} =
  Worker.create_router(worker, %{
    mediaCodecs: media_codecs
  })
```
* Pros
  * Can be sent to remote node
  * Extensive language support for the process lifetime
  * Can be pipe_producer_to_router to router in remote node
* Cons
  * Has message passing overhead in function call

### Reference
``` elixir
# create Worker reference struct
{:ok, worker} = Mediasoup.create_worker()
# router struct has reference property as reference
{:ok, router} =
  Worker.create_router(worker, %{
    mediaCodecs: media_codecs
  })
```
* Pros
  * no overhead
* Cons
  * Can not be sent to remote node
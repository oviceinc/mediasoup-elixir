# start the current node as a manager
# Note that you must have ensured that epmd has been started before using this lib; typically with epmd -daemon.
exclude =
  case LocalCluster.start() do
    :ok -> []
    _ -> [cluster: true]
  end

ExUnit.start(exclude: exclude)

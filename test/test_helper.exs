# start the current node as a manager
# Note that you must have ensured that epmd has been started before using this lib; typically with epmd -daemon.
exclude =
  case LocalCluster.start() do
    :ok -> [leakcheck: true]
    _ -> [cluster: true, leakcheck: true]
  end

opt = [exclude: exclude]

with_leakcheck = ExUnit.configuration() |> Keyword.fetch!(:include) |> Enum.member?(:leakcheck)

opt =
  if with_leakcheck do
    opt ++ [max_cases: 1]
  else
    opt
  end

ExUnit.start(opt)

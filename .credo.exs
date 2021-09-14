%{
  configs: [
    %{
      name: "default",
      checks: [
        {Credo.Check.Readability.LargeNumbers, only_greater_than: 99_999},
        # ... other checks omitted for readability ...
      ]
    }
  ]
}

%{
  configs: [
    %{
      name: "default",
      checks: %{
        disabled: [
          {Credo.Check.Refactor.LongQuoteBlocks, []}
        ]
      }
      # files etc.
    }
  ]
}

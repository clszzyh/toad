%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/"],
        excluded: []
      },
      checks: [
        # {Credo.Check.Refactor.PerceivedComplexity, false},
        {Credo.Check.Refactor.MapInto, false},
        {Credo.Check.Design.TagTODO, false},
        {Credo.Check.Readability.ModuleDoc, false},
        {Credo.Check.Warning.LazyLogging, false},
        {Credo.Check.Warning.IoInspect, false},
        {Credo.Check.Refactor.CyclomaticComplexity, max_complexity: 13},
        {Credo.Check.Refactor.Nesting, max_nesting: 4}
        # {Credo.Check.Refactor.PerceivedComplexity, priority: :low, max_complexity: 11}
      ]
    }
  ]
}

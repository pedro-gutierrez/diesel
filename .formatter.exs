locals_without_parents = [tag: :*, child: :*, attribute: :*]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parents,
  export: [
    locals_without_parens: locals_without_parens
  ]
]

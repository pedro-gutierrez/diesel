import Config

config :diesel, Latex.Dsl, packages: [Latex.Dsl.Music]
config :diesel, Latex, generators: [Latex.Html]

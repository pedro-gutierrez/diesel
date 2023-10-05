import Config

config :diesel, Latex.Dsl, blocks: [Latex.Dsl.Music]
config :diesel, Latex, generators: [Latex.Html]

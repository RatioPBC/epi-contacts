[
  # Why does this cause IntelliJ IDEA to not be able to format *.ex files?
  # import_deps: [:ecto, :phoenix],
  #
  inputs: ["*.{ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{ex,exs}"],
  line_length: 120,
  subdirectories: ["priv/*/migrations"]
]

# Diesel

[![Hex.pm](https://img.shields.io/hexpm/v/diesel.svg)](https://hex.pm/packages/diesel)
[![Documentation](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/diesel)

**Diesel** is a powerful toolkit for building Domain Specific Languages (DSLs) in Elixir. Create declarative, structured, and reusable DSLs with compile-time validation and flexible code generation.

## Features

- **Declarative**: Clean, HTML-like syntax that's easy to read and write
- **Structured**: Compile-time schema validation ensures correctness  
- **Reusable**: Same DSL can power multiple code generators
- **Flexible**: Support for custom parsers, generators, and tag definitions
- **Type-safe**: Rich attribute validation with kinds, constraints, and defaults

## Installation

Add `diesel` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:diesel, "~> 0.8"}
  ]
end
```

## Quick Start

Here's an example of building a database schema DSL:

### 1. Define your DSL library

```elixir
defmodule MyApp.Schema do
  use Diesel, otp_app: :my_app
end
```

### 2. Define the DSL structure

```elixir
defmodule MyApp.Schema.Dsl do
  use Diesel.Dsl,
    otp_app: :my_app,
    tags: [
      MyApp.Schema.Dsl.Table,
      MyApp.Schema.Dsl.Column,
      MyApp.Schema.Dsl.Index,
      MyApp.Schema.Dsl.Relationship,
      MyApp.Schema.Dsl.Validation
    ]
end
```

### 3. Define your tags

```elixir
defmodule MyApp.Schema.Dsl.Table do
  use Diesel.Tag

  tag do
    attribute :name, kind: :atom
    attribute :primary_key, kind: :atom, default: :id
    child :column, min: 1
    child :index, min: 0
    child :relationship, min: 0
  end
end

defmodule MyApp.Schema.Dsl.Column do
  use Diesel.Tag

  tag do
    attribute :name, kind: :atom
    attribute :type, kind: :atom, 
              one_of: [:string, :integer, :boolean, :datetime, :decimal, :text]
    attribute :null, kind: :boolean, default: true
    attribute :unique, kind: :boolean, default: false
    attribute :size, kind: :integer, required: false
    child :validation, min: 0
  end
end

defmodule MyApp.Schema.Dsl.Relationship do
  use Diesel.Tag

  tag do
    attribute :type, kind: :atom, one_of: [:belongs_to, :has_many, :has_one]
    attribute :name, kind: :atom
    attribute :target, kind: :atom
    attribute :foreign_key, kind: :atom, required: false
  end
end
```

### 4. Use your DSL

```elixir
defmodule MyApp.UserSchema do
  use MyApp.Schema

  database do
    table :users do
      column :email, type: :string, null: false, unique: true do
        validation :format, pattern: ~r/@/
        validation :length, min: 5, max: 100
      end
      
      column :name, type: :string, null: false, size: 255 do
        validation :length, min: 2, max: 50
      end
      
      column :age, type: :integer do
        validation :range, min: 13, max: 120
      end
      
      column :created_at, type: :datetime, null: false
      column :updated_at, type: :datetime, null: false
      
      index [:email], unique: true
      index [:created_at]
      
      relationship :has_many, :posts, target: :posts, foreign_key: :user_id
      relationship :has_one, :profile, target: :profiles
    end

    table :posts do
      column :title, type: :string, null: false, size: 200 do
        validation :length, min: 5, max: 200
      end
      
      column :content, type: :text, null: false
      column :published, type: :boolean, default: false
      column :user_id, type: :integer, null: false
      
      index [:user_id]
      index [:published, :created_at]
      
      relationship :belongs_to, :user, target: :users
    end
  end
end
```

## Core Concepts

### Tags

Tags are the building blocks of your DSL. Each tag can have:

- **Attributes**: Named parameters with type validation
- **Children**: Nested tags with cardinality constraints  
- **Content**: Raw values or modules

```elixir
defmodule MyDsl.Tag do
  use Diesel.Tag

  tag do
    attribute :name, kind: :atom, required: true
    attribute :size, kind: :integer, min: 1, max: 1000
    child :nested_tag, min: 0, max: 5
    child kind: :module, min: 1, max: 1  # unnamed children
  end
end
```

### Parsers

Transform your DSL definition into custom data structures:

```elixir
defmodule MyApp.Schema.Parser do
  @behaviour Diesel.Parser

  def parse(definition, _opts) do
    # Transform table definitions into Schema structs
    tables = extract_tables(definition)
    relationships = extract_relationships(definition)
    
    # Return enhanced definition with parsed data
    definition
    |> put_in([:parsed_tables], tables)
    |> put_in([:relationships], relationships)
  end

  defp extract_tables({:database, _attrs, children}) do
    children
    |> Enum.filter(&match?({:table, _attrs, _children}, &1))
    |> Enum.map(&parse_table/1)
  end
end
```

### Generators

Generate code from your parsed DSL:

```elixir
defmodule MyApp.Schema.EctoGenerator do  
  @behaviour Diesel.Generator

  def generate(definition, _opts) do
    tables = get_in(definition, [:parsed_tables])
    
    quote do
      # Generate Ecto schema modules
      unquote_splicing(generate_schemas(tables))
      
      # Generate migration functions
      def migration_up do
        unquote_splicing(generate_create_tables(tables))
      end
    end
  end

  defp generate_schemas(tables) do
    Enum.map(tables, fn table ->
      quote do
        defmodule unquote(Module.concat(__MODULE__, table.name)) do
          use Ecto.Schema
          
          schema unquote(Atom.to_string(table.name)) do
            unquote_splicing(generate_fields(table.columns))
          end
        end
      end
    end)
  end
end
```

## Attribute Types

Diesel supports rich attribute validation:

```elixir
attribute :name, kind: :atom                    # Basic types
attribute :size, kind: :integer, min: 1, max: 255      # Numeric constraints  
attribute :type, kind: :atom, one_of: [:string, :integer]  # Enums
attribute :options, kind: :keyword_list          # Complex types
attribute :*, kind: :*                          # Generic attributes (0.8.0+)
```

## Advanced Features

- **Kernel Conflicts**: Handle conflicts with Kernel functions using `:overrides`
- **Debug Mode**: Inspect generated code during compilation with `debug: true`
- **Custom Naming**: Override default module naming conventions
- **Multiple Parsers**: Chain multiple parsers for complex transformations
- **Conditional Generation**: Generate different code based on parsed data

Example with advanced options:

```elixir
defmodule MyApp.Schema do
  use Diesel,
    otp_app: :my_app,
    overrides: [import: 2],  # Handle kernel conflicts
    parsers: [
      MyApp.Schema.Parser,
      MyApp.Schema.ValidationParser,
      MyApp.Schema.RelationshipParser
    ],
    generators: [
      MyApp.Schema.EctoGenerator,
      MyApp.Schema.MigrationGenerator,
      MyApp.Schema.GraphQLGenerator
    ]
end
```

## Documentation

For detailed guides and examples:

- [Installation Guide](https://hexdocs.pm/diesel/installation.html)
- [Tutorial](https://hexdocs.pm/diesel/tutorial.html) 
- [Parsers Guide](https://hexdocs.pm/diesel/parsers.html)
- [Generators Guide](https://hexdocs.pm/diesel/generators.html)
- [API Reference](https://hexdocs.pm/diesel/api-reference.html)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
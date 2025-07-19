defmodule Route.Dsl.Route do
  @moduledoc false
  use Diesel.Tag

  tag do
    attribute :name, kind: :string
    attribute :method, kind: :string, default: "get"
    child :model, min: 0
    child :view, min: 0
  end
end

defmodule Route.Dsl.Model do
  @moduledoc false
  use Diesel.Tag

  tag do
    child kind: :module, min: 1, max: 1
  end
end

defmodule Route.Dsl.View do
  @moduledoc false
  use Diesel.Tag

  tag do
    child kind: :module, min: 1, max: 1
  end
end

defmodule Route.Dsl do
  @moduledoc false
  use Diesel.Dsl,
    otp_app: :diesel,
    tags: [
      Route.Dsl.Route,
      Route.Dsl.Model,
      Route.Dsl.View
    ]
end

defmodule Route.Parser do
  @moduledoc false
  @behaviour Diesel.Parser

  @impl true
  def parse({:route, attrs, children}, _opts) do
    path = Keyword.fetch!(attrs, :name)
    models = for {:model, _, [module]} <- children, do: module
    views = for {:view, _, [module]} <- children, do: module

    {path, List.first(models), List.first(views)}
  end
end

defmodule Route do
  @moduledoc false
  use Diesel,
    otp_app: :diesel,
    generators: []

  defstruct [:path, :model, :view]
end

defmodule Index do
  @moduledoc false

  use Route

  route("/")
end

defmodule Home do
  @moduledoc false

  use Route

  route("/home")
end

defmodule CreateOrder do
  @moduledoc false

  use Route

  route(name: "/orders", method: "post")
end

defmodule Form.Dsl.Form do
  @moduledoc false
  use Diesel.Tag

  tag do
    attribute :model, kind: :module, required: true
    attribute :command, kind: :module, required: true
  end
end

defmodule Form.Dsl do
  @moduledoc false
  use Diesel.Dsl,
    otp_app: :diesel,
    root: Form.Dsl.Form
end

defmodule Form.Parser do
  @moduledoc false
  @behaviour Diesel.Parser

  @impl true
  def parse(definition, _opts), do: definition
end

defmodule Form do
  @moduledoc false
  use Diesel,
    otp_app: :diesel,
    dsl: Form.Dsl,
    parser: Form.Parser,
    generators: []
end

defmodule SignUpForm do
  @moduledoc false
  use Form

  form(
    model: User,
    command: SignUp
  )
end

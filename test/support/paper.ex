defmodule Paper do
  @moduledoc false
  use Latex

  latex version: 3.14159265 do
    document size: "{{ document.size }}" do
      packages([:babel, :graphics])

      section title: "Introduction" do
        subsection title: "Details" do
          music staffs: 2 do
            instrument(name: "Piano")
          end
        end
      end
    end
  end
end

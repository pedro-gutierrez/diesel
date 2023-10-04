defmodule Paper do
  use Latex

  latex do
    document size: :a4 do
      package(name: :babel)

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

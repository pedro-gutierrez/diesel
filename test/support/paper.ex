defmodule Paper do
  use Latex

  latex do
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

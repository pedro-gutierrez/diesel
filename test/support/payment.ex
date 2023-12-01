defmodule SendToGateway do
end

defmodule NotifyParties do
end

defmodule Payment do
  @moduledoc false
  use Fsm

  fsm do
    state :pending do
      on event: :created do
        action(SendToGateway)
        next(state: :sent)
      end
    end

    state :sent, timeout: 60 do
      on event: :success do
        action(NotifyParties)
        next(state: :accepted)
      end

      on event: :error do
        action(NotifyParties)
        next(state: :declined)
      end

      on event: :timeout do
        action(NotifyParties)
        next(state: :declined)
      end
    end

    state :accepted do
    end

    state :declined do
    end
  end
end

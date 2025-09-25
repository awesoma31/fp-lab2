defmodule AvlSet.Node do
  @moduledoc false

  @type t(a) :: %__MODULE__{
          key: a,
          left: t(a) | nil,
          right: t(a) | nil,
          height: non_neg_integer()
        }

  defstruct [:key, :left, :right, height: 1]
end

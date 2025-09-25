defmodule AvlSet do
  @moduledoc """
  Иммутабельное полиморфное множество на AVL.
  """

  @type cmp(a) :: (a, a -> boolean)
  @type t(a) :: %__MODULE__{
          root: AvlSet.Node.t(a) | nil,
          cmp: cmp(a),
          size: non_neg_integer()
        }

  defstruct root: nil, cmp: &Kernel.</2, size: 0

  @spec new(cmp(a)) :: t(a) when a: var
  def new(cmp \\ &</2), do: %__MODULE__{cmp: cmp}
end

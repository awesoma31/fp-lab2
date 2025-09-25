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

  defp h(nil), do: 0
  defp h(%AvlSet.Node{height: ht}), do: ht

  defp with_height(%AvlSet.Node{left: l, right: r} = n) do
    %{n | height: 1 + max(h(l), h(r))}
  end

  @doc """
  get balance of a node
  """
  defp bal(nil), do: 0
  defp bal(%AvlSet.Node{left: l, right: r}), do: h(l) - h(r)

  defp fix(nil), do: nil

  defp fix(n) do
    n = with_height(n)

    case bal(n) do
      # левое тяжёлое: LL или LR
      b when b > 1 ->
        if bal(n.left) < 0, do: rot_lr(n), else: rot_r(n)

      # правое тяжёлое: RR или RL
      b when b < -1 ->
        if bal(n.right) > 0, do: rot_rl(n), else: rot_l(n)

      _ ->
        n
    end
  end

  # rotations
  defp rot_l(%AvlSet.Node{right: %AvlSet.Node{} = r} = n) do
    rl = r.left
    n1 = %AvlSet.Node{n | right: rl} |> with_height()
    r1 = %AvlSet.Node{r | left: n1} |> with_height()
    r1
  end

  defp rot_r(%AvlSet.Node{left: %AvlSet.Node{} = l} = n) do
    lr = l.right
    n1 = %AvlSet.Node{n | left: lr} |> with_height()
    l1 = %AvlSet.Node{l | right: n1} |> with_height()
    l1
  end

  defp rot_lr(%AvlSet.Node{left: %AvlSet.Node{} = l} = n) do
    n |> Map.put(:left, rot_l(l)) |> rot_r()
  end

  defp rot_rl(%AvlSet.Node{right: %AvlSet.Node{} = r} = n) do
    n |> Map.put(:right, rot_r(r)) |> rot_l()
  end
end

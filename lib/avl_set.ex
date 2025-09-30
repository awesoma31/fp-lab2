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

  alias AvlSet.Node

  defstruct root: nil, cmp: &Kernel.</2, size: 0

  @spec new(cmp(a)) :: t(a) when a: var
  def new(cmp \\ &</2), do: %__MODULE__{cmp: cmp}

  @spec empty?(t(any())) :: boolean
  def empty?(%__MODULE__{size: n}), do: n == 0

  @spec size(t(any())) :: non_neg_integer
  def size(%__MODULE__{size: n}), do: n

  @spec member?(t(a), a) :: boolean when a: var
  def member?(%__MODULE__{root: t, cmp: lt}, x), do: mem(t, x, lt)

  defp mem(nil, _x, _lt), do: false

  defp mem(%Node{key: k, left: l, right: r}, x, lt) do
    cond do
      lt.(x, k) -> mem(l, x, lt)
      lt.(k, x) -> mem(r, x, lt)
      true -> true
    end
  end

  # эквивалентность по компаратору
  defp eq(a, b, lt), do: not lt.(a, b) and not lt.(b, a)

  @spec insert(t(a), a) :: t(a) when a: var
  def insert(%__MODULE__{root: t, cmp: lt, size: n} = s, x) do
    {t2, grew?} = ins(t, x, lt)
    %{s | root: t2, size: n + if(grew?, do: 1, else: 0)}
  end

  defp ins(nil, x, _lt), do: {%Node{key: x, left: nil, right: nil, height: 1}, true}

  defp ins(%Node{key: k, left: l, right: r} = n, x, lt) do
    cond do
      lt.(x, k) ->
        {l2, g} = ins(l, x, lt)
        {%Node{n | left: l2} |> fix(), g}

      lt.(k, x) ->
        {r2, g} = ins(r, x, lt)
        {%Node{n | right: r2} |> fix(), g}

      true ->
        # дубликат
        {n, false}
    end
  end

  @spec delete(t(a), a) :: t(a) when a: var
  def delete(%__MODULE__{root: t, cmp: lt, size: n} = s, x) do
    {t2, removed?} = del(t, x, lt)
    %{s | root: t2, size: n - if(removed?, do: 1, else: 0)}
  end

  defp del(nil, _x, _lt), do: {nil, false}

  defp del(%Node{key: k, left: l, right: r} = n, x, lt) do
    cond do
      lt.(x, k) ->
        {l2, rm} = del(l, x, lt)
        {%Node{n | left: l2} |> fix(), rm}

      lt.(k, x) ->
        {r2, rm} = del(r, x, lt)
        {%Node{n | right: r2} |> fix(), rm}

      true ->
        # нашли k == x
        case {l, r} do
          {nil, _} ->
            {r, true}

          {_, nil} ->
            {l, true}

          _ ->
            {succ, r2} = pop_min(r)
            {%Node{n | key: succ, right: r2} |> fix(), true}
        end
    end
  end

  # извлечь минимальный ключ из поддерева, вернуть {min_key, новое_поддерево}
  defp pop_min(%Node{key: k, left: nil, right: r}), do: {k, r}

  defp pop_min(%Node{left: l} = n) do
    {m, l2} = pop_min(l)
    {m, %Node{n | left: l2} |> fix()}
  end

  defp h(nil), do: 0
  defp h(%AvlSet.Node{height: ht}), do: ht

  defp with_height(%AvlSet.Node{left: l, right: r} = n) do
    %{n | height: 1 + max(h(l), h(r))}
  end

  defp bal(nil), do: 0
  defp bal(%AvlSet.Node{left: l, right: r}), do: h(l) - h(r)

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

  # ---------- folds ----------
  @spec reduce_left(t(a), acc, (acc, a -> acc)) :: acc when a: term(), acc: term()
  def reduce_left(%__MODULE__{root: t}, acc, f), do: in_order(t, acc, f)

  defp in_order(nil, acc, _f), do: acc

  defp in_order(%Node{left: l, key: k, right: r}, acc, f) do
    acc1 = in_order(l, acc, f)
    acc2 = f.(acc1, k)
    in_order(r, acc2, f)
  end

  @spec reduce_right(t(a), acc, (acc, a -> acc)) :: acc when a: term(), acc: term()
  def reduce_right(%__MODULE__{root: t}, acc, f), do: rev_in_order(t, acc, f)

  defp rev_in_order(nil, acc, _f), do: acc

  defp rev_in_order(%Node{left: l, key: k, right: r}, acc, f) do
    acc1 = rev_in_order(r, acc, f)
    acc2 = f.(acc1, k)
    rev_in_order(l, acc2, f)
  end

  # ---------- filter ----------
  @spec filter(t(a), (a -> as_boolean(term()))) :: t(a) when a: term()
  def filter(%__MODULE__{} = set, pred) do
    reduce_left(set, new(set.cmp), fn acc, k ->
      if pred.(k), do: insert(acc, k), else: acc
    end)
  end

  # ---------- map ----------
  @spec map(t(a), (a -> b), cmp(b)) :: t(b) when a: term(), b: term()
  def map(%__MODULE__{} = set, fun, cmp2) do
    reduce_left(set, new(cmp2), fn acc, k ->
      insert(acc, fun.(k))
    end)
  end

  # ---------- monoid ----------
  @spec empty() :: t(any())
  def empty, do: new(&Kernel.</2)

  @spec combine(t(a), t(a)) :: t(a) when a: term()
  def combine(%__MODULE__{} = a, %__MODULE__{} = b) do
    # вставляем меньший в больший (чтобы меньше аллокаций)
    if a.size >= b.size, do: fold_into(a, b), else: fold_into(b, a)
  end

  defp fold_into(dst, src) do
    reduce_left(src, dst, fn acc, k -> insert(acc, k) end)
  end

  # ---------- equality via co-iteration ----------
  @spec equal?(t(a), t(a)) :: boolean when a: term()
  def equal?(%__MODULE__{size: sa, cmp: lt} = a, %__MODULE__{size: sb} = b) do
    sa == sb and coeq(iter(a.root), iter(b.root), lt)
  end

  # (опц.) лексикографическое сравнение множеств по возр. порядку
  # specs
  @spec compare(t(a), t(a)) :: :lt | :eq | :gt when a: term()
  @spec compare(t(a), t(a), cmp(a)) :: :lt | :eq | :gt when a: term()

  # реализация
  def compare(%__MODULE__{} = a, %__MODULE__{} = b),
    do: compare(a, b, a.cmp)

  def compare(%__MODULE__{} = a, %__MODULE__{} = b, lt),
    do: co_cmp(iter(a.root), iter(b.root), lt)

  # ---------- iterator (private) ----------
  defp iter(tree), do: push_left(tree, [])

  defp push_left(nil, st), do: st
  defp push_left(%Node{left: l} = n, st), do: push_left(l, [n | st])

  # next: :done | {key, new_iter}
  defp next([]), do: :done
  defp next([%Node{key: k, right: r} | st]), do: {k, push_left(r, st)}

  # равенство без материализации списков
  defp coeq(ita, itb, lt) do
    case {next(ita), next(itb)} do
      {:done, :done} -> true
      {:done, _} -> false
      {_, :done} -> false
      {{ka, ia2}, {kb, ib2}} -> eq(ka, kb, lt) and coeq(ia2, ib2, lt)
    end
  end

  # лексикографическое сравнение
  defp co_cmp(ita, itb, lt) do
    case {next(ita), next(itb)} do
      {:done, :done} ->
        :eq

      {:done, _} ->
        :lt

      {_, :done} ->
        :gt

      {{ka, ia2}, {kb, ib2}} ->
        cond do
          ka == kb -> co_cmp(ia2, ib2, lt)
          lt.(ka, kb) -> :lt
          true -> :gt
        end
    end
  end
end

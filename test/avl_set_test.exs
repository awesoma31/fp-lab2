defmodule AvlSetTest do
  use ExUnit.Case, async: true
  alias AvlSet, as: S
  alias AvlSet.Node

  defp from_list(xs, cmp \\ &</2), do: Enum.reduce(xs, S.new(cmp), &S.insert(&2, &1))

  defp check_inv(nil), do: {true, 0, 0}

  defp check_inv(%Node{left: l, right: r}) do
    {ok_l, h_l, n_l} = check_inv(l)
    {ok_r, h_r, n_r} = check_inv(r)
    h = 1 + max(h_l, h_r)
    bal = h_l - h_r
    ok = ok_l and ok_r and abs(bal) <= 1
    {ok, h, n_l + n_r + 1}
  end

  defp valid?(%S{root: t, size: n}) do
    {ok, _h, nodes} = check_inv(t)
    ok and nodes == n
  end

  test "insert/member idempotent + size" do
    s = S.new() |> S.insert(2) |> S.insert(1) |> S.insert(3) |> S.insert(2)
    assert S.member?(s, 1)
    assert S.member?(s, 2)
    assert S.member?(s, 3)
    refute S.member?(s, 4)
    assert S.size(s) == 3
    assert valid?(s)
  end

  test "delete works and keeps AVL invariant" do
    s = from_list(1..10)
    s = S.delete(s, 5) |> S.delete(1) |> S.delete(10) |> S.delete(42)
    assert S.size(s) == 7
    refute S.member?(s, 5)
    assert valid?(s)
  end

  test "filter keeps only predicate-true" do
    s = from_list(1..10)
    s2 = S.filter(s, fn x -> rem(x, 2) == 0 end)
    for x <- 1..10, do: assert(S.member?(s2, x) == (rem(x, 2) == 0))
    assert valid?(s2)
  end

  test "map with new comparator" do
    s = from_list([1, 3, 5])
    s2 = S.map(s, &Integer.to_string/1, &Kernel.</2)
    assert S.member?(s2, "1")
    assert S.member?(s2, "3")
    assert S.member?(s2, "5")
    assert S.size(s2) == 3
    assert valid?(s2)
  end

  test "monoid: empty, combine" do
    a = from_list([1, 3, 5])
    b = from_list([2, 3, 4])
    e = S.empty()
    ab = S.combine(a, b)
    ba = S.combine(b, a)
    assert S.equal?(a, S.combine(a, e))
    assert S.equal?(ab, ba)
    assert S.size(ab) == 5
    assert valid?(ab)
  end

  test "equal? compares element-wise order-independently" do
    a = from_list([3, 1, 2])
    b = from_list([1, 2, 3])
    c = from_list([1, 2, 4])
    assert S.equal?(a, b)
    refute S.equal?(a, c)
  end

  test "equal? uses comparator: strings case-insensitive" do
    cmp = fn a, b -> String.downcase(a) < String.downcase(b) end
    a = ["A", "b"] |> Enum.reduce(AvlSet.new(cmp), &AvlSet.insert(&2, &1))
    b = ["a", "B"] |> Enum.reduce(AvlSet.new(cmp), &AvlSet.insert(&2, &1))
    assert AvlSet.equal?(a, b)
  end

  test "equal? uses comparator: tuples by id only" do
    cmp = fn {i1, _}, {i2, _} -> i1 < i2 end
    a = [{1, "x"}, {2, "y"}] |> Enum.reduce(AvlSet.new(cmp), &AvlSet.insert(&2, &1))
    b = [{2, "other"}, {1, "zzz"}] |> Enum.reduce(AvlSet.new(cmp), &AvlSet.insert(&2, &1))

    assert AvlSet.equal?(a, b)
  end
end

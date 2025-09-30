defmodule AvlSetPropTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  alias AvlSet, as: S

  # helpers
  defp from_list(xs, cmp \\ &</2), do: Enum.reduce(xs, S.new(cmp), &S.insert(&2, &1))
  defp ints_gen, do: StreamData.list_of(StreamData.integer(), max_length: 120)

  defp strs_gen,
    do:
      StreamData.list_of(StreamData.string(:alphanumeric, min_length: 0, max_length: 6),
        max_length: 80
      )

  property "correspondence with MapSet" do
    check all(xs <- ints_gen()) do
      s = from_list(xs)
      m = MapSet.new(xs)

      assert S.size(s) == MapSet.size(m)
      Enum.each(xs, fn x -> assert S.member?(s, x) == MapSet.member?(m, x) end)

      s2 = from_list(MapSet.to_list(m))
      assert S.equal?(s, s2)
    end
  end

  property "monoid laws" do
    check all(
            xs <- ints_gen(),
            ys <- ints_gen(),
            zs <- ints_gen()
          ) do
      a = from_list(xs)
      b = from_list(ys)
      c = from_list(zs)
      e = S.empty()

      # identity
      assert S.equal?(S.combine(a, e), a)
      assert S.equal?(S.combine(e, a), a)

      # associativity
      left = S.combine(a, S.combine(b, c))
      right = S.combine(S.combine(a, b), c)
      assert S.equal?(left, right)

      # commutativity
      assert S.equal?(S.combine(a, b), S.combine(b, a))
    end
  end

  property "idempotency" do
    check all(xs <- ints_gen()) do
      a = from_list(xs)
      assert S.equal?(S.combine(a, a), a)

      x = if xs == [], do: 0, else: hd(xs)
      a1 = S.insert(a, x)
      a2 = S.insert(a1, x)
      assert S.equal?(a1, a2)
    end
  end

  property "inorder traversal is sorted" do
    check all(xs <- ints_gen()) do
      s = from_list(xs)

      {ok, _prev} =
        S.reduce_left(s, {true, :first}, fn {ok, prev}, x ->
          cond do
            prev == :first -> {ok, x}
            prev <= x -> {ok and true, x}
            true -> {false, x}
          end
        end)

      assert ok
    end
  end

  property "delete matches MapSet difference" do
    check all(
            xs <- ints_gen(),
            ys <- ints_gen()
          ) do
      s0 = from_list(xs)
      m0 = MapSet.new(xs)

      s = Enum.reduce(ys, s0, &S.delete(&2, &1))
      m = Enum.reduce(ys, m0, &MapSet.delete(&2, &1))

      assert S.size(s) == MapSet.size(m)
      Enum.each(m, fn x -> assert S.member?(s, x) end)
      Enum.each(xs, fn x -> assert S.member?(s, x) == MapSet.member?(m, x) end)
    end
  end

  property "equal? via comparator (case-insensitive strings)" do
    check all(
            xs <- strs_gen(),
            ys <- strs_gen()
          ) do
      cmp = fn a, b -> String.downcase(a) < String.downcase(b) end
      norm = fn list -> Enum.map(list, &String.downcase/1) |> MapSet.new() end

      a = from_list(xs, cmp)
      b = from_list(ys, cmp)

      assert S.equal?(a, b) == (norm.(xs) == norm.(ys))
    end
  end
end

# ЛР 2 **AVL Set (Elixir)**

# Чураков Александр P3331

## Требования:

1. Функции:

* добавление и удаление элементов;
* фильтрация;
* отображение (map);
* свертки (левая и правая);
* **структура должна быть моноидом.**

2. Структуры данных должны быть **неизменяемыми**.

3. Библиотека должна быть протестирована в рамках **unit testing**.

4. Библиотека должна быть протестирована в рамках **property-based тестирования** (как минимум 3 свойства, включая свойства моноида).

5. Структура должна быть **полиморфной**.

6. Требуется использовать **идиоматичный для технологии стиль программирования**.
* *Примечание:* некоторые языки позволяют получить большую часть API через реализацию небольшого интерфейса. Так как лабораторная работа про ФТ, а не про экосистему языка — необходимо реализовать их вручную и по возможности обеспечить совместимость.

7. Обратите внимание:

* **API должно быть реализовано для заданного интерфейса** и он не должно "протекать". На уровне тестов — в первую очередь нужно протестировать именно API (dict, set, bag).
* **Должна быть эффективная реализация функции сравнения** (не наивное приведение к спискам, их сортировка с последующим сравнением), реализованная на уровне API, а не внутреннего представления.

### Структуры и типы

```elixir
defmodule AvlSet.Node do
  @type t(a) :: %__MODULE__{key: a, left: t(a) | nil, right: t(a) | nil, height: non_neg_integer()}
  defstruct [:key, :left, :right, height: 1]
end

defmodule AvlSet do
  @type cmp(a) :: (a, a -> boolean())
  @type t(a) :: %__MODULE__{root: AvlSet.Node.t(a) | nil, cmp: cmp(a), size: non_neg_integer()}
  defstruct root: nil, cmp: &</2, size: 0
```

### Базовый API множества

```elixir
@spec new(cmp(a)) :: t(a) when a: term()
@spec empty?(t(any())) :: boolean()
@spec size(t(any())) :: non_neg_integer()
@spec member?(t(a), a) :: boolean() when a: term()
@spec insert(t(a), a) :: t(a) when a: term()
@spec delete(t(a), a) :: t(a) when a: term()
```

### AVL-утилиты и ротации

```elixir

defp h(nil), do: 0
defp with_height(%Node{left: l, right: r}=n), do: %{n | height: 1 + max(h(l), h(r))}
defp bal(%Node{left: l, right: r}), do: h(l) - h(r)

defp fix(n) do
  n = with_height(n)
  case bal(n) do
    b when b > 1 -> if bal(n.left) < 0, do: rot_lr(n), else: rot_r(n)
    b when b < -1 -> if bal(n.right) > 0, do: rot_rl(n), else: rot_l(n)
    _ -> n
  end
end

# ротации O(1): rot_l/rot_r/rot_lr/rot_rl
  defp rot_l(%AvlSet.Node{right: %AvlSet.Node{} = r} = n) do
    rl = r.left
    n1 = %AvlSet.Node{n | right: rl} |> with_height()
    %AvlSet.Node{r | left: n1} |> with_height()
  end

  defp rot_r(%AvlSet.Node{left: %AvlSet.Node{} = l} = n) do
    lr = l.right
    n1 = %AvlSet.Node{n | left: lr} |> with_height()
    %AvlSet.Node{l | right: n1} |> with_height()
  end

  defp rot_lr(%AvlSet.Node{left: %AvlSet.Node{} = l} = n),
    do: n |> Map.put(:left, rot_l(l)) |> rot_r()

  defp rot_rl(%AvlSet.Node{right: %AvlSet.Node{} = r} = n),
    do: n |> Map.put(:right, rot_r(r)) |> rot_l()

```

### Свёртки, filter, map

```elixir
@spec reduce_left(t(a), acc, (acc, a -> acc)) :: acc when a: term(), acc: term()
@spec reduce_right(t(a), acc, (acc, a -> acc)) :: acc when a: term(), acc: term()

@spec filter(t(a), (a -> as_boolean(term()))) :: t(a) when a: term()
@spec map(t(a), (a -> b), cmp(b)) :: t(b) when a: term(), b: term()
```


### Моноид и сравнение

```elixir
@spec empty() :: t(any())
@spec combine(t(a), t(a)) :: t(a) when a: term() 

@spec equal?(t(a), t(a)) :: boolean when a: term() 
@spec compare(t(a), t(a)) :: :lt | :eq | :gt when a: term()
@spec compare(t(a), t(a), cmp(a)) :: :lt | :eq | :gt when a: term()
```

*`equal?` и `compare` реализованы ко-итерацией двух inorder-итераторов;*

---

## Тесты

### Unit-тесты

* **Инвариант AVL** после `insert/delete` (проверка балансов и высот рекурсивно).
* **Идемпотентность вставки**, корректный `size`, `member?`.
* **filter/map**: корректное содержимое, сохранение инварианта.
* **Моноид**: `empty/0`, `combine/2`, равенство `combine(a,b)==combine(b,a)`.
* **equal? по cmp**: case-insensitive строки; кортежи, сравнение по `id`.

`test/avl_set_test.exs`

```elixir
test "insert/member idempotent + size" do
  s = AvlSet.new() |> AvlSet.insert(2) |> AvlSet.insert(1) |> AvlSet.insert(2)
  assert AvlSet.member?(s, 1)
  assert AvlSet.size(s) == 2
  assert valid_avl?(s)
end

test "equal? uses comparator (case-insensitive)" do
  cmp = fn a,b -> String.downcase(a) < String.downcase(b) end
  a = Enum.reduce(~w[A b], AvlSet.new(cmp), &AvlSet.insert(&2,&1))
  b = Enum.reduce(~w[a B], AvlSet.new(cmp), &AvlSet.insert(&2,&1))
  assert AvlSet.equal?(a, b)
end
```

### Property-based

1. **Моноид** (identity, associativity, commutativity для union):
   `combine(a, empty) == a`,
   `combine(a, combine(b,c)) == combine(combine(a,b), c)`,
   `combine(a,b) == combine(b,a)`.
2. **Идемпотентность**: `combine(a,a) == a`, `insert(insert(s,x),x) == insert(s,x)`.
3. **Соответствие MapSet**: `size`, `member?`, `equal?`.
4. **Inorder-отсортированность** по `cmp`.
5. **Delete соответствует MapSet.delete/2`**.

`test/avl_set_prop_test.exs`

```elixir
use ExUnitProperties
defp ints_gen(), do: StreamData.list_of(StreamData.integer(), max_length: 120)

property "monoid laws" do
  check all xs <- ints_gen(), ys <- ints_gen(), zs <- ints_gen() do
    a = from_list(xs); b = from_list(ys); c = from_list(zs); e = AvlSet.empty()
    assert AvlSet.equal?(AvlSet.combine(a,e), a)
    assert AvlSet.equal?(AvlSet.combine(a, AvlSet.combine(b,c)),
                         AvlSet.combine(AvlSet.combine(a,b), c))
    assert AvlSet.equal?(AvlSet.combine(a,b), AvlSet.combine(b,a))
  end
end
```

## Выводы
* Полиморфизм через `t(a)` + внешний `cmp/2` делает структуру универсальной. Равенство множеств корректно определяется по компаратору.
* Первый раз узнал о PBT.



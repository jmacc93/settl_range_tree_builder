
# Component types

`1d42b3aa-2802-5888-bd7b-7639f15437ed`

Here is:
* `LinearIndex`
* `LListIndex`
* `LListElementBody`

---

`1c693d3c-e5d7-5ab4-85cf-201ceb18c30a`

These are proxies for integer array indices:
* `LinearIndex` -- to get the Nth next element from the first element in a linked list
* `LListIndex` -- to get a linked list element by its internal index

A note about the different between `LinearIndex` and `LListIndex`: all (most) of the public-facing linked list functions that take indices can take either a `LinearIndex` or `LListIndex`. All `LinearIndex` values are converted to `LListIndex` values. When you use a `LinearIndex`, the system has to find the real `LListIndex` to use, so using `LinearIndex` values is inherently slower than using `LListIndex` values

To be clear: `LinearIndex(n)` means count from the beginning of the list, following the current element's `nextIndex` to the next element, and keep doing this `n` times
Whereas, a `LListIndex(n)` literally means get the `list.elements[n]` value, ie: the `n` here is the internal location of the element in the container the `list` uses to store its `elements`

To be even clearer: the elements in `list.elements` are out of order (that's what makes the linked list work), and they track their own order using their `prevIndex` and `nextIndex` properties. `LinearIndex` goes by the elements' own ordering (via their `prevIndex`/`nextIndex` properties), and `LListIndex` goes by the `list.elements` order. There may be gaps in the `list.elements` array, so some `LListIndex` values aren't valid despite being inside the bounds of the `list.elements` array

Some guidelines:
* `0 <= someLinearIndex < list.length` is ok
* `0 <= someLListIndex < list.length` is *not* ok
* `0 <= someLListIndex < list.elements.length` is ok
* `someLinearIndex++` is ok
* `someLListIndex++` is *not* ok

---

`49413a06-a121-531b-83e9-08fc16ddcfce`

To make an element into a linked list element use:
`mixin LListElementBody!()` in your linked list element's body
(alternatively, just provide `LListIndex prevIndex, nextIndex` properties)


# Linked list body

`007dc309-4cfe-52d0-b612-17ed4b781764`

To make your type into a linked list, use:
`mixin LListBody!(Element)` in your type's body
Where `Element` is your linked list element type

This linked list is actually an array with elements that remember their ordering. So its suitable to use when you want to be able to add and remove things cheaply from anywhere in the array, since all you have to do is update the order of the elements to do so

Internally the 'null' locations in the array are kept track of using a stack of indices. When there are no available indices, the internal array is resized

Note: There will likely be cache misses when you iterate a linked list unless the list is linearized (the internal order matches the iteration order)

eg Of usage of a linked list (taken from unit tests, see `bdaf793a-bd1f-58ff-a858-b6e228e7c55a`):
```D
struct LListElement(T) {
  mixin LListElementBody!();
  T value;
  
  bool opEquals(T other) { return value == other; }
  T opCast(Type : T)() { return value; }
}
struct LList(T) {
  mixin LListBody!(LListElement!T);
}

auto list = LList!int()
list.append(1)
list.append(2)
list.append(3)
list.append(4)
list.remove(LinearIndex(2))
assert(list.length == 3)
assert(list == [1, 2, 4])
```

---

`92c9607c-b877-508e-aaf5-76aa64892297`

Here are the properties provided:
* `Stack!LListIndex availableIndices` -- The list of 'null' indices of the `elements` properties that new elements will be placed into
* `Element[] elements` -- What the elements are actually held in. The order they're canonically iterated in isn't the same as their real order in this array, and some elements are 'null' which means they aren't part of the canonical ordering of the elements
* `LListIndex firstIndex, lastIndex` -- The indices of the first and last in the `elements` array

---

`38a608e9-b0ae-5829-b39a-c1ddeb45954c`

`bool empty()`
Use to determine if there are no elements in the list

---

`4563b7d7-7dc3-5263-8222-8b711037da18`

`void increaseAvailableCapacity()`
Resizes the internal available indices array and adds those new values to the available indices stack. Use this when the stack is empty. Note: resizes the array, which involves a copy to a new memory location

---

`22b7bc43-f49f-55c2-9662-8f543850d9fa`
`LListIndex getAvailableIndex()`
Returns a new internal index an element can be put into. Note: this index MUST be used once its returned from this function

---

`3b085ebd-692c-5ddf-a6dd-71c0ca772ba0`

`LListIndex append(T1 arg1, T2 arg2, ...)`
`LListIndex prepend(T1 arg1, T2 arg2, ...)`
These construct a new `Element` with `Element(arg1, arg2, ...)` and add it to the start / end of the list. It returns the element's index which is the new `firstIndex` / `lastIndex` 

---

`611191a7-c0b8-596f-b97d-9519166b5016`

You can use catenation to add stuff to the list:
`list ~= value`

---

`255ff887-04d9-5ef6-837c-4c64f99ba9aa`

`ref This remove(LListIndex index)`
`ref This remove(LinearIndex index)`
This removes the given element from the list. It returns the list itself so you can chain it with other functions

---

`eeb59652-a849-5033-837a-0cdbef670b95`

`LListIndex[] traversalOrder()`
This returns the traversal order of the elements -- ie: the order you get when you get successive `nextIndex` values. Its unlikely all of the internal array indices will be represented

---

`f18ecd4e-277b-5f64-a9f0-533def16f1fc`

`ref This swap(LListIndex firstIndex, LListIndex secondIndex)`
Changes the positions of the elements at the given first and second indices in the traversal order

---

`88add1a3-b3a2-596d-a862-76d6c1dc30b2`

You can use the form `list[index]` to get both `index` of `LListIndex` and `LinearIndex`

This is just another form of the following function:

`f6610aa9-5333-5c9c-880c-54f9845e9e9b`

`ref Element get(LListIndex index)`
`ref Element get(LinearIndex index)`
This just returns a reference to the element at the given index

---

`0e69355b-cb43-50c6-b8dc-1bc88d7b6f7e`

`LListIndex nonlinearIndex(LListIndex index)`
Is an identity function on its first element: it just returns the given `index`

`LListIndex nonlinearIndex(LinearIndex index)`
This finds the corresponding `LListIndex` for the given `LinearIndex`

`a3eecca7-7d5a-5a04-8923-4127f833463c`

The following 2 functions do the opposite of the above: turn their indices into `LinearIndex`s

`LinearIndex linearizeIndex(LinearIndex index)`
Is an identity function on its first element: it just returns the given `index`

`LinearIndex linearizeIndex(LListIndex index)`
Finds the corresponding `LinearIndex` for the given `LListIndex`

---

`1c081a8e-1f34-536c-915e-f89137ab7387`

`bool isIndexValid(LListIndex index)`
Checks to make sure the given index points to an element in the list via a search. This is costly and especially highly costly for huge lists. Theres also no guarantee that the element at the given `index` wasn't removed and a new element added between the times the `index` was collected and the `isIndexValid` was call

---

`183ed6b2-76c4-5e0b-ab43-697d64a7d75b`

Some functions are provided for debugging and invariant checking. The main function here is `doPostModificationCheck` which should be sprinked after any *finished* modifications, ie: the soonest point after a modification where the list is in a correct state, not in the middle of a modification for debugging purposes. These aren't used in release builds

---

`989b080c-4e83-5f8b-ac03-ac2d9a2b2ac8`

You can compare a linked list to an array like `list == array`

---

`b0bf0f82-50cc-5943-b29b-e24277cfd4a8`
`T[] asArray(T)()`
This converts each element in the list to a `T` and returns the array of all those conversions in the canonical ordering
Use like: `asArray!T`, eg: `asArray!int`

Note: whatever you mix `LListElementBody` into determines how each element is converted to a `T` value

---

`632ae617-8fab-599b-aff8-00f0aebdad65`

`string prettyString()`
This makes a representation of the list in the canonical ordering for debugging purposes

---

`f60d571f-4ae5-57f8-8125-e7fb4cfe4ad1`

You can iterate a linked list using foreach:
`foreach(LListIndex index; list)`
`foreach(LListIndex index, const(Element) element; list)`

# Unit tests

See `bdaf793a-bd1f-58ff-a858-b6e228e7c55a` for examples of using linked lists

See `lib.d` and specifically `9fd54247-bbce-5385-955d-4a39d3429a5f` for information about the `assertString` functions in use in the unittests
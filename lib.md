
`364c8f85-49a7-54cb-955b-d8c44091a701`

`from!module`

Is the typical Dlang inline import idiom

eg: `from!"std.stdio".writeln("Hello")`

Note: whenever you import a module in Dlang, everything in that module is imported, including things you aren't using, *except* for templated functions, which are only compiled when they are used (because each template parameter sequence is compiled as a different function)

---

`8dafd46c-75f8-542d-a335-3e3d1a9b1f55`

`bool hasModule!module`

This returns true if `import module` will work (the module is available), and false if not

*Also*: you can force a module to always return `false` from `hasModule` by setting `--version=noModule_MODULENAMEHERE` where `MODULENAMEHERE` is the name of the module with all `.` replaced with `_`

eg: `hasModule!"std.stdio"` would usually return `true`

To make `hasModule!"std.stdio"` always return `false` you'd set `--version=noModule_std_stdio`

---

`9716cf05-325c-5f2c-9de3-9f784c0966d1`

`bool iff(bool a, bool b)`

Equivalent to the logical expression $a \Leftrightarrow b$, which is equivalent to $\lnot a \vee b$ ie `!a || b`. Only true if both `a` and `b` have the same values, ie: `a == b`

---

`01efa8ec-74ed-5334-933c-c48a49e4bc83`

`T echo(T)(T value)`

Takes `value` which can be anything, prints the value, then returns the value. Can be inserted directly into any expression to print a value

eg: `echo(echo(1) + echo(2))`

Which prints 1, then prints 2, then prints 3

---

`d95131cb-75a9-51bc-b87f-a86db950010b`

`T dbgEchoFull(T value, moreArgs...)`

Acts like `echo` and `dbglnFull`: it prints the current line, module, and function, `value` and all of `moreArgs` its other arguments, then returns `value`

`3661b33a-34fb-52ba-b92a-a55f44de4b6d`

`T dbgEcho(T value, moreArgs...)`

Acts like `echo` and `dbglnFull`: it prints the current line, `value` and all of `moreArgs` its other arguments, then returns `value`. This is like `dbgEchoFull` but prints the line instead of the line, module, and function, to avoid visual spam

---

`0afc45ec-1e3f-55b0-95c7-9b41cbf15f0b`

`writeStack()`

Prints the current stack to the console

eg: `foo(); writeStack(); assert(0);`

Use when you know the program is going to crash

---

`4cbbdcd4-6dbf-589f-8b62-bfcceaf64b69`

`ulong countStackDepth()`

Returns the depth of the stack. Even in a `main` function, this will probably by greater than `0`

Note: this is an expensive operation and should really only be used when debugging, on exceptions, etc

---

`9fd54247-bbce-5385-955d-4a39d3429a5f`

`string assertString(string msg = "")(string stringToAssert, string variableName1, string variableName2, ...)`

This is to assert an expression while also printing the value of various things to the console, along with a stack trace. Its meant to be used with CTFE and mixin statements. ie: `mixin(str)` where `str` was produced by a function at compile time, and in this case `str` is the result of calling `assertString`

This is essentially just a very verbose assert whose parameters have to be strings
eg: `mixin(assertString!"x is greater than y"("x < y", "x", "y"))`

---

`e1c33342-b5d6-5501-9014-077f6bb433e0`

`void tracedAssert(bool assertionValue, string msg = "")`

An assert + stack trace. Use exactly like a regular assert. ie: `assert(x < 5, "x >= 5")` is equivalent to `tracedAssert(x < 5, "x >= 5")`

---

`0a8baa0e-bb69-577d-938e-6dac82dc91f3`

`void dbglnFull()`

Prints the current line, module, and function the `dbgln` statement appears in. And see `dbgln` below for the version that only prints the current line

eg:

```D
f(); // executes
dbgln; // prints the line, module, function
g(); // error here, but you can't see that
dbgln; // this doesn't print, so you know the problem was g
h();
```

Can be quickly thrown down to print which lines are being executed without going into a debugger

---

`20ae8807-f15b-5b2f-ab7c-536bd6c192c8`

`void dbgln()`

Just like `dbglnFull` but only prints the current line, to avoid visible spam

---

`b16a1820-bc95-54bf-adda-3c0b3bcaff0c`

`mixin(dbgwritelnFulLMixin("someVar", "someOtherVar", ...))`

This prints the current line, module, and function and prints the name and value of each of the variables given

`mixin(dbgwritelnMixin("someVar", "someOtherVar", ...))`
Same as above but only prints the line. This is useful because you avoid the visual span from the other version

eg:
```D
int x = 5
float y = 7.1
mixin(dbgwritelnMixin("x", "y"))
```
Prints something like:
```
3:
  x == 5
  y == 7.1
```

---

`47536b16-ae51-555d-8e8f-325907bed3b4`

`mixin(dbgWriteMixin!(K("someVar"), "Heres some text", ...))`

This is like `dbgwritelnMixin` above, but:

* Allows printing text (all string arguments) as well as expressions (strings wrapped in `K`, eg: `K(someVar)`)
* Prints red dashes `-` that increase in number with the stack depth
* Prints on a single line

---

`b167010c-423d-5eeb-b24a-b64cc10b7a4c`

`void dbgwrite(args...)`

Acts just like `std.stdio.writeln` but writes the line its on as well. Use when debugging

---

`687579a2-fb95-5903-af0c-e31735688bec`

Here are some ANSI escape code strings for styling output text

`redFg`, `blueFg`, `greenFg`

`redBg`, `blueBg`, `greenBg`

`boldTxt`

Turn these off using:
`noStyle`

eg:
`writeln(redFg, "Error!", noStyle)`

---

`80c68167-9efb-5508-bff8-af5f534553b6`

`textRedFg(string)`, `textBlueFg(string)`, `textGreenFg(string)`

`textRedBg(string)`, `textBlueBg(string)`, `textGreenBg(string)`

`textBold(string)`

This turns into a parameter sequence that can be used with `write`, `writeln`, etc

eg: `write("Some ", textRedFg("red"), " text")` ie equivalent to `write("Some ", redFg, "red", noStyle, " text")`

---

`c54fc86c-1f0f-51ed-b1ef-fb26e533dc4f`

`enum bool isNullable(T)`

This is primarily a helper for `Maybe` to determine if a type can be assigned a value of `null`

eg: `isNullable!(int*)` is `true`, `isNullable!MyStruct` is `false`, and for classes its `true`, for value types its `false`, etc

Theres also `enum bool isNullInit(T)` which is `true` if `T` is initially `null` and `false` if `T` isn't initialized to `null`

---

`dbb7e8b4-dc97-5875-b78a-67c7d6d5e9c8`

`Maybe!T`

Is equivalent to `T` if a `T` variable can be set to `null` (which is canonically the invalid type)

And, is `T` plus a validity indicator if `T` isn't nullable. The validity indicator (which is the `valid` property) is a standing for a `null` value when `T` is something that can't be set to `null`

eg:

```D
Maybe!int maybeFoundValue = searchForAndReturnInvalidIfCouldntFind(list, someValue);
if(maybeFoundValue.valid)
  writeln("Found the value: ", maybeFoundValue.value);
else
  writeln("Didnt find value");
```

---

`107b6052-6d0e-5d72-a977-a2f974e53b34`

`Stack!T`

This is essentially equivalent to `T[]` but adds:

* `T pop()` -- the unsafe version of `popSafe` always either crashes the program or returns the top of the stack. Use `isEmpty` to determine if you should call this function. This should be $O(1)$
* `Maybe!T popSafe()` -- return the top of the stack or an invalid `Maybe!T`. This should be $O(1)$
* `bool isEmpty()` -- always $O(1)$
* `T peek()` and the safe version `Maybe!T peekSafe()` -- like `pop` but doesn't remove the top element, so, eg: you can do: `stack.peek() == stack.peek()` -- This should be $O(1)$
* `void push(T value)` -- add a value to the top of the stack. This should on average be $O(1)$

---

`e35ddfb7-96a4-5e73-b846-9883d693bf80`

`TwoEndedStack!T`

This is like a `Stack` which you can push and pop stuff from either end of. Behind the scenes, it is an array with a contiguous subsequence of valid elements (its contents) that loops past its end to its start. eg: `[d X X a b c]` is a representation of the array of a `TwoEndedStack!T`, its contents are `a b c d`, and its invalid elements are `X X` at positions `1` and `2`. You fill up the `X` invalid elements by pushing (fill from below) to the start (`a` position) or end (`d` position), and when there are no spots available, the internal array is resized to add more `X`s

* `T popEnd()` and `T popStart()` and the safe versions `Maybe!T popEndSafe()` and `Maybe!T popStartSafe()`. These all should be $O(1)$
* `T peekEnd()` and `T peekStart()` and the safe versions `Maybe!T peekEndSafe()` and `Maybe!T peekStartSafe()`. These all should be $O(1)$
* `void pushEnd` and `void pushStart` -- add elements to the start or end of the stack. If you only push stuff to the end and pop from the start, then a two ended stack acts like a *first-in first-out* container, if you only push and pop stuff from one end, then it acts like a *first-in last-out* container. These should both almost always be $O(1)$
* `bool isEmpty()`

---

`b76550a2-c711-530b-8a4f-fe39f17476d6`

`T[] intersect(T[] list1, T[] list2)`
Returns the elements in common between the two input lists

eg: `intersect([1, 2, 3], [2, 3, 4]) == [2, 3]`

---

`da26d3a3-a730-59c3-8aa9-77cd3c28dc0e`

`T[] swap(T[] array, ulong i, ulong j)`
Makes a copy of `array` with `array[i]` and `array[j]` switched. ie: The output is `array` but the jth location is `array[i]` and the ith location is `array[j]`

eg: `swap([0, 5, 0, 0], 1, 2) == [0, 0, 5, 0]`

---

`17a6edf7-f8a8-55f5-ae03-b8da7620e7a1`

`Maybe!ulong findIndex(T[] array, T valueToFind)`
Finds the index of `valueToFind` in `array` and returns it wrapped in a `Maybe!ulong` (a maybe of an index), OR, if the function doesn't find `valueToFind` it returns a `Maybe!(ulong).invalid` -- ie: a `Maybe!ulong` with a `false` value for its `valid` property

eg: `findIndex([1, 2, 3], 2) == 1`, with `findIndex([1, 2, 3], 2).valid == true` and `findIndex([1, 2, 3], 10).valid == false`

---

`aa009fe4-2327-54ce-a8f8-075f3a45f623`

`ref T[] removeIndex(ref T[] array, ulong indexToRemove)`
Removes `array[indexToRemove]` from `array`. Returns a reference to `array`, so it can be chained. This is *in-place*, so `array` is modified

eg: For `array = [1, 2, 3]`, `removeIndex(array, 1)` makes `array == [1, 3]`

---

`69159255-e312-5d36-8b49-73bd26b827da`

`NonemptyString` this is a proxy for `string` with an invariant that prevents it from being empty
As with all string proxies, its primary effect is to inform the programmer what the string should be like

`89bd62f7-571e-5e64-ab15-587500581c8a`

`enum NonemptyString[] makeNonempty(string[] array)`
Turns a regular string array into a `NonemptyString` array at compile-time. Afaict, this has to be used to turn string array literals to `NonemptyString` array literals
eg: `NonemptyString[] myStrings = makeNonempty!["abc", "xyz", "qwe"]`

The more general version of `makeNonempty` is `literalAs`, which applies to any types

---

`443af432-a1eb-5e49-94cd-942d123fb1c7`

`enum T[] literalAs(T, R[] array)`
Tries to cast each element of `array` into type `T` and returns the equivalent `T[]` at compile-time. Afaict, this has to be used for all proxy types' array literals
eg: `MyCustomInt[] intArray = literalAs!(MyCustomInt, [1, 2, 3])`

---

`e44747b8-5e5d-57b6-a099-4904d0c22d8f`

`DebugEmpty` is nothing, and is intended as a replacement for debug values when not in release builds. Theoretically it takes up no memory and does nothing

`enum auto debugValue(value)`
Returns `value` in debug builds and returns `DebugEmpty` in non-debug builds
eg: `auto varToUseOnlyInDebugBuilds = debugValue!123`

`DebugType(T)`
Acts like `T` in debug builds and `DebugEmpty` in non-debug builds. Behaves just like `debugValue` above but for types

---

`530ab49f-e5cf-5531-96e5-5f440a83a3ed`

`alternates(() {...}, () {...}, ...)`
This function runs each of the function bodies in sequence and stops after one of them succeeds. The idea is that if there is an error in one of the function bodies then it runs the next function body. If there isn't an error in the first function then that is the only one ran, otherwise it goes onto the next, and so on

This absorbs all `Exception`s in its functions' bodies, so keep that in mind

eg:
```D
int whichSucceeded = -1;
alternates(() {
  throw new Exception("Error 1!");
  whichSucceeded = 1;
}, () {
  throw new Exception("Error 2!");
  whichSucceeded = 2;
}, () {
  whichSucceeded = 3;
}, () {
  whichSucceeded = 4;
});
assert(whichSucceeded == 3)
```

---

`2b19627e-0d25-53f6-bb9b-e9e2ff4d5d65`

`T appendToExceptions(lazy T mightThrowException, string messageToAppend)`

Appends `messageToAppend` to all messages that `mightThrowException` throws. ie: It catches exceptions, appends its `messageToAppend` to the caught exception's message, and rethrows a new exception with the concatenated message. Note: always rethrows a new `Exception`, so don't expect anything from the original exception to be preserved except its message

Very useful for adding information to upward-bubbling exceptions (eg: where the exception came from)

eg: `JSONValue json = parseJson(input).appendToExceptions("While converting input to json")`

The above is equivalent to:

`JSONValue json = appendToExceptions(parseJson(input), "While converting input to json")`

---

`740ede60-885a-5305-ad7a-a3febf7c0bc2`

`string readEntireFile(std.stdio.File file)`

Returns all of the input file's contents all at once. You can call it on `std.stdio.stdin`, ie *stdin*, as well

eg: `string fileContents = readEntireFile(someFilePath)`

---

`ceea52dc-cd9d-5cd2-897f-3ae09a365923`

`string ctReplace!(original, from, to)`

Replaces all occurrences of `from` in `original` with `to`

eg: `ctReplace!("aBBc", "B", "C") == "aXXc"`

---

`98004b1f-1976-5b30-b673-86d0721e5a6b`

`enum bool isVersion(string versionName)`

An expression version of `version(versionName)`. Returns whether the current version flag `versionName` is enabled

This enables the pattern:

```D
static if(isVersion!someVersion)
  ...
else
  ...
```

If `versionName` is `debug` then it acts like a `debug` condition block, ie:

```D
static if(isVersion!debug) {
  ...
}
// eq to:
debug {
  ...
}
```

---

`10ee45c3-6643-5c18-9f98-fddb0c83328e`

`enum bool isDebug(string debugVersion)`

An expression version of `debug(debugVersion)`. Returns whether the current debug flag `debugVersion` is enabled

If `debugVersion` isn't given, or is empty, then it acts like the empty `debug` condition block:

```D
static if(isDebug!()) {
  ...
}
// eq to:
debug() {
  ...
}
```

---

`cddf19ef-2ec3-5af9-a552-a100c6123e52`

`bool isAlphanumWord(string str)`

Checks whether `str` only has characters like abcdefghijklmnopqrstuvwxyz, ABCDEFGHIJKLMNOPQRSTUVWXYZ, 0123456789, ie: matches the regex `^[a-z0-9A-Z]+$`

eg: `isAlphanumWord("abcdefg")` is `true`, and `isAlphanumWord("abc_defg")` is `false`

---

`52eba935-9c14-50aa-8ad6-fedb99e7c46f`

`string escapeJsonHazardousCharacters(string str)`

Escapes `\`, `"`, and `\n`, ie: replaces them with `\\`, `\"`, and `\\n`, so that the string can be saved into a json file

---

`b3751d54-eca6-5351-8185-4a3d597e4fbc`

`struct Enumerated(string memberString...)`

Makes a proxy for an `enum` with all the `memberString` arguments as member names, with:

* `static Enumerated!(...) from(string memberName)` -- interprets its given `memberName` input as one of the enum members
* `bool hasValue(string memberName)` -- checks whether the `Enumerated!(...)`'s enum value equals `memberName`
* `bool atLeast(string memberName)` -- checks whether the `Enumerated!(...)`'s enum value is greater than `memberName`

eg: `alias MyEnum = Enumerated!("A", "B", "C")` then you can do: `auto x = MyEnum.from("B")`, which makes `x` have a `B` enum value

eg: `if(x.hasValue("C")) writeln("is C") else writeln("is A or B")` prints `is A or B`
and: `if(x.atLeast("B")) writeln("is B or C") else writeln("is A")` prints `is B or C`

---

`a5aea0f2-6481-545b-a747-843adb8103cf`

`T when(T)(lazy T value, bool condition, lazy T defaultValue)`

Evaluates and returns `value` if `condition` is true, otherwise returns `defaultValue`. Is the expression version of `if(condition) { return value; } else {return defaultValue ;}`

The other form:

`void when(lazy void noValue, bool condition)`

When `condition` is true, evaluates its `noValue` parameter and does nothing with it

This enables the pattern: `writeln(...).when(...)` which calls the `writeln` whenever the condition is true
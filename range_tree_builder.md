

`0cef84d4-1eaf-52c9-b60c-bf37d71d858d`

These are a collection of types that make understanding and parsing patterns easier. The most important type is `PatternSystem` which is fed into the primary function of this module: `buildRangeTree`

* `PatternSystem` -- Like a `Pattern[]`
* `Pattern` -- Like `[PatternConditional, PatternOrSeq openers, PatternOrSeq closers]`
* `PatternConditional` -- Like `[string name | "*", string parentName | "*", string ancestorName | "*"]`
* `PatternOrSeq` -- Like a `PatternAndSeq[]`
* `PatternAndSeq` -- Like a `PatternAtom[]`
* `PatternAtom` -- Like `[string label | "*", string value | "*"]`

With all of this together, `PatternSystem` looks like:

```
[
  [
    [string name, string parentName, ancestorName], // conditional
    [ // openers or sequence
      [ // single open and sequence
        [string label, string value], // pattern atom
        ...
      ],
      ...
    ],
    [...] // closers or sequence
  ]
]
```

---


There are two formats `PatternSystems` are built from: the custom one, and the json one

An example custom `PatternSystem` source:

```
fnBlock topLevel  >  fn-leftParenthesis  > rightParenthesis // <- single Pattern source line
leftCurlyBrace  >  rightCurlyBrace // <- another Pattern source line
...
```

An example json `PatternSystem` source:

```json
[
  {
    "conditional": {"name": "fnBlock", "parent": "topLevel"},
    "openers": [["fn", "leftParenthesis"]],
    "closers": [["rightParenthesis"]]
  },
  {
    "openers": [["leftCurlyBrace"]],
    "closers": [["rightCurlyBrace"]]
  }
]
```

---


The custom format in general looks like:

```
patternLine
patternLine
...
```

Where each `patternLine` looks like:

```
[conditional  > ]  orSeq  >  orSeq
```

Where `[xxx]` means the `xxx` is optional. So, `[conditional > ]` means that part isn't required

The first `orSeq` is the *openers* sequence. The openers delimit the left side of new ranges to be collected in new child nodes in the output range tree. ie: An opener starts a new range, which corresponds to a level deeper in an output range tree

The second `orSeq` is the *closers* sequence. The closers delimit the right hand side of ranges. When one of the currently-opened patterns closers is found, the range of the pattern is collected and inserted into the output range tree

---

Each `conditional` represents the *conditionals* section, which holds the pattern name, required parent name, and required ancestor label, and looks like any of the following:

```
wordOrStar 
wordOrStar wordOrStar
wordOrStar wordOrStar wordOrStar
```

Where `wordOrStar` is either a string with no whitespace using only a-z, 0-9, and A-Z, or is a `*` character

The first `wordOrStar` is the pattern name. Named patterns can be used to constrain which patterns open via the parent and ancestor constraint `wordOrStar` values

The second `wordOrStar` is the required parent name. If a pattern has a required parent name, then that pattern (x) will only open if the latest-opened pattern's name matches x's required parent name

The third `wordOrStar` is the required ancestor name. If a pattern has one, then it will only open if one of its ancestors has that name

eg: If the currently opened pattern stack has names like: `[topLevel, *, fnBlock, *, loopBlock]` (ie: a pattern with `topLevel` was pushed first, then an unnamed pattern, then one with a name of `fnBlock`, etc, with the `loopBlock` named pattern latest), then a pattern with a conditional like `* fnBlock` won't open, one with `* loopBlock` will open, and one with `* * fnBlock` will open

When a conditional's name, required parent name, or required ancestor name is `*` then that represents every possible value, and practically means ignore that value. So, you can skip the name part in a conditional by doing something like `* x y`. Similarly, you can skip the name and parent parts by doing `* * y`. And a conditional like `* * *` does nothing

---

In the `PatternSystem` custom format spec above, each `orSeq` represents a set of possible `andSeq`s that can match as an opener or closer. `orSeq`s look any of the following:

```
andSeq
andSeq andSeq
andSeq andSeq andSeq
...
```

eg: `fn-leftParenthesis leftBracket` is an `orSeq` of two `andSeq`s

And, `andSeq`s represent a contiguous subsequence of atoms. These look like:

```
atom
atom-atom
atom-atom-atom
...
```

Where each `atom` is like:

```
atomLabelWord[:atomValue]
```

And both `atomLabelWord` and `atomValue` are strings using only a-z, A-Z, and 0-9 characters or are `*`

eg of `atom`s: `fn`, `leftParenthesis:(`, `name:walter`, etc

An `andSeq` like `name:walter-jumps:up-lands:floor` stands for a subsequence with labels like `[name, jumps, lands]` with values like `[walter, up, floor]`, where each of the `name:walter`, `jumps:up`, and `lands:floor` are atoms, and mean that a labeled value `name:walter` has to be followed by `jumps:up` which has to be followed by `lands:floor`, etc

---

`9fa3ed63-ac89-568c-a7ae-14be4de461c7`

`struct RangeNode`

Is the `Node` type of the `RangeTree` below. `RangeNode` has `start` and `end` values representing the start and end of the range in a `LabeledValue[]` array the `RangeNode` represents. It also has a `patternName` which represents the pattern name that opened and closed it

`struct RangeTree`

Is a tree of nested ranges. These correspond to where nested opener-and-closer-delimited ranges were detected in the `LabeledValue[]` array given to `buildRangeTree`

eg, For a pattern represented with the pattern system with the single line `leftParenthesis > rightParenthesis`, and a `LabeledValue[]` like the array `[A, leftParenthesis, B, leftParenthesis, C, rightParenthesis, D, rightParenthesi]` which looks like the string `A(B(C)D)`, the returned `RangeTree` might be represented like:

```
[
  range: [0, 7],
  children: [
    range: [1, 7],
    children: [
      range: [3, 5],
      children: []
    ]
  ]
]
```

---

`565ceed2-a886-5a1c-97d3-85f50321de73`

`struct LabeledValue`

This is like `[string label, string value]`

And has a some helper functions to parse `LabeledValues` is different formats:

* `static LabeledValue fromLine(string source)` -- Takes a string like `label:value` and splits it at the first `:` seen to make a single `LabeledValue`
* `static LabeledValue[] seqFromLineSeq(string source)` -- Takes a string like `label:value\nlabel:value\n...`, splits it by whitespace, and then splits each line
* `static LabeledValue fromJson(JSONValue jsonSource)` -- Takes a json object like `{"label": "...", "value": "..."}` or `["...", "..."]`, and builds the analogous `LabeledValue`
* `static LabeledValue seqFromJson(JSONValue jsonSource)` -- Takes a json array with objects or 2-element arrays as elements

---

`df825834-21e9-5494-beb2-2ee7dbcabdae`

`RangeTree buildRangeTree(LV)(PatternSystem patternSystem, LV[] labeledValues, bool closeImplicitly = false)`

This takes a pattern system, a sequence of values with `label` and `value` properties, and returns a range tree with nested ranges (pairs of indices) of where the pattern system's pattern's openers and closers were detected in the `labeledValues` array. `closeImplicitly == true` Means pattern closers don't have to be seen before the end of the `labeledValues`, and any remaining opened but not closed patterns will be closed automatically

---

`31cf8c6d-47ca-5336-be61-b2b487e7fd43`

The `main` function won't be compiled in unless the `--version=rangeTreeBuilderMain` version switch is supplied





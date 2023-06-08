import lib : NonemptyString, Maybe, appendToExceptions, dbgEcho, Enumerated;
version(assert) import lib : assertString, writeStack, from, hasModule, isVersion, when, textGreenFg;
debug import lib : dbgWriteMixin, dbgln, K;

import std.json: JSONValue, JSONType;

version(fast) {
  version = noValidation;
}

alias Verbosity = Enumerated!("none", "steps", "all");
Verbosity verbosity;

// 0cef84d4-1eaf-52c9-b60c-bf37d71d858d

struct PatternSystem {
  Pattern[] patterns;
  alias patterns this;
  
  invariant {
    mixin(assertString("patterns.length > 0", "patterns.length", "patterns"));
  }
  
  this(string source) {
    import std.regex : ctRegex, split;
    
    // (?<!\\) before \n means you can continue one line onto the next using a slash (\) at the very end of the line
    auto enum lineSplitterRegex = ctRegex!(r"(?<!\\)\n+");
    
    ulong lineNumber = 0;
    foreach(string possiblyCommentedLine; source.split(lineSplitterRegex) ) {
      import std.conv: to;
      Maybe!Pattern possibleLinePattern = appendToExceptions(
        Pattern.fromLine(possiblyCommentedLine), 
        "on line number " ~ lineNumber.to!string ~ 
        " : \"" ~ possiblyCommentedLine ~ "\""
      );
      if(!possibleLinePattern.valid)
        continue;
      patterns ~= possibleLinePattern;
      lineNumber++;
    }
  }
  
  this(JSONValue jsonValue) {
          
    ulong patternNumber = 0;
    foreach(JSONValue patternJson; jsonValue.array) {
      import lib: appendToExceptions;
      import std.conv: to;
    
      appendToExceptions((){
        patterns ~= Pattern(patternJson);
      }(), "In pattern " ~ patternJson.toString ~ " (number " ~ patternNumber.to!string ~ ")");
      
      patternNumber++;
    }
  }
  
  struct SearchResult {
    Pattern* patternRef;
    PatternAndSeq* andSeqRef;
    ulong index;
    bool found = false;
    
    static SearchResult notFound() { return SearchResult(); }
  }
  SearchResult searchOpeners(LV)(string[] contextNames, LV[] labeledValues) {
    ulong currentIndex = 0;
    foreach(ref Pattern currentPattern; patterns) {
      if(!currentPattern.conditional.matches(contextNames))
        continue;
      
      PatternAndSeq* maybeFoundAndSeq = currentPattern.openers.findAndSeq!LV(labeledValues);
      if(maybeFoundAndSeq !is null) {
        alias foundAndSeq = maybeFoundAndSeq;
        return SearchResult(&currentPattern, foundAndSeq, currentIndex, true);
      }
      
      currentIndex++;
    }
    return SearchResult.notFound;
  }
}

unittest { // pattern system search
  struct LV {
    string label;
    string value;
  }
  auto patternSystem = PatternSystem("A B > C D\n X Y > Z W");
  PatternSystem.SearchResult result = patternSystem.searchOpeners(["Q", "W"], [LV("A", "a")]);
  mixin(assertString("result.index == 0", "result", "*result.patternRef", "*result.andSeqRef", "result.index", "result.found"));
  mixin(assertString("result.found", "result", "*result.patternRef", "*result.andSeqRef", "result.index", "result.found"));
  result = patternSystem.searchOpeners(["Q", "W"], [LV("X", "x")]);
  mixin(assertString("result.index == 1", "result", "*result.patternRef", "*result.andSeqRef", "result.index", "result.found"));
  mixin(assertString("result.found", "result", "*result.patternRef", "*result.andSeqRef", "result.index", "result.found"));
}

struct Pattern {
  PatternConditional conditional;
  PatternOrSeq openers;
  PatternOrSeq closers;
  
  invariant {
    mixin(assertString("openers.length > 0", "openers.length", "openers"));
    mixin(assertString("closers.length > 0", "closers.length", "closers"));
  }
  
  static Maybe!Pattern fromLine(string possiblyCommentedLine) { // eg: possiblyCommentedLine == "  ?A > B-C:c > D E // asdf"
    import std.regex : ctRegex, split;
    import std.string : strip;
    import std.conv : to;
    
    if(possiblyCommentedLine.length == 0)
      return Maybe!Pattern.invalid; // ignore empty lines
    
    // remove comment
    enum auto commentSeparatorRegex = ctRegex!(r"\/\/"); // comment starts with "//" ends with newline or EOF
    string[] lineAndComment = possiblyCommentedLine.split(commentSeparatorRegex);
    
    // remove surrounding whitespace
    string unstrippedLine = lineAndComment[0];
    string line = unstrippedLine.strip(); // eg: line == "!A B-C:c > D E"
    
    if(line.length == 0)
      return Maybe!Pattern.invalid; // ignore whitespace-only, and comment-only lines
    
    // split line into lhs and rhs
    enum auto sideSplitterRegex = ctRegex!(r"\s*>\s*");
    string[] conditionalsOpenersAndClosers = line.split(sideSplitterRegex); // eg: ["?A", "B-C:c", "D E"]
    
    string conditionalsString, openersString, closersString;
    if(conditionalsOpenersAndClosers.length == 3) { // cond > open > close   form
      conditionalsString = conditionalsOpenersAndClosers[0]; // eg: "?A"
      openersString      = conditionalsOpenersAndClosers[1]; // eg: "B-C:c"
      closersString      = conditionalsOpenersAndClosers[2]; // eg: "D E"
    } else if(conditionalsOpenersAndClosers.length == 2) { // open > close   form
      conditionalsString = "";
      openersString      = conditionalsOpenersAndClosers[0];
      closersString      = conditionalsOpenersAndClosers[1];
    } else {
      throw new Exception("Missing a '>' separator, or too many '>' separators: " ~ line);
    }
    
    if(openersString.length <= 1)
      throw new Exception("Line has no openers: " ~ line);
    if(closersString.length <= 1)
      throw new Exception("Line  has no closers: " ~ line);
    
    Maybe!Pattern ret;
    ret.valid = true;
    
    ret.conditional = PatternConditional(conditionalsString);
    ret.openers     = PatternOrSeq(openersString); // openers and closers looks just like [[PatternAtom(__), PatternAtom(__),...], [__],...]
    ret.closers     = PatternOrSeq(closersString);
    
    return ret;
  }
  
  this(JSONValue jsonValue) {
    import lib: appendToExceptions;
    
    if(jsonValue.type != JSONType.object)
      throw new Exception(q"[Pattern must be an object (ie like: {"conditional": "...", "openers": "...", "closers": "..."})]");
    
    JSONValue[string] patternJson = jsonValue.object();
    
    JSONValue* conditionalJson = "conditional" in patternJson;
    if(conditionalJson !is null)
      conditional = PatternConditional(*conditionalJson).appendToExceptions("In conditional for pattern \"" ~ jsonValue.toString() ~ "\"");
    
    JSONValue* openersJson = "openers" in patternJson;
    if(openersJson !is null)
      openers = PatternOrSeq(*openersJson).appendToExceptions("In opener for pattern \"" ~ jsonValue.toString() ~ "\"");
    else
      throw new Exception("No openers in pattern");
    
    JSONValue* closersJson = "closers" in patternJson;
    if(closersJson !is null)
      closers = PatternOrSeq(*closersJson).appendToExceptions("In closer for pattern \"" ~ jsonValue.toString() ~ "\"");
    else
      throw new Exception("No closers in pattern");
  }
    
}

unittest { // form
  alias A   = PatternAtom;
  
  auto line = "  A > B-C:c > D E // asdf  ";
  auto patternMaybe = Pattern.fromLine(line);
  mixin(assertString("patternMaybe.valid", "patternMaybe", "line"));
  auto pattern = patternMaybe.value;
  
  Pattern targetPattern;
  targetPattern.conditional = PatternConditional("A", "*", "*");
  targetPattern.openers = PatternOrSeq([
    PatternAndSeq([A("B", "*"), A("C", "c")])
  ]);
  targetPattern.closers = PatternOrSeq([
    PatternAndSeq([A("D", "*")]), PatternAndSeq([A("E", "*")])
  ]);
  
  mixin(assertString("pattern == targetPattern", "pattern", "targetPattern", "line"));
}

unittest { // empty line is invalid
  auto line = "  // asdf  ";
  auto patternMaybe = Pattern.fromLine(line);
  mixin(assertString("!patternMaybe.valid", "patternMaybe", "line"));
}

struct PatternConditional {
  NonemptyString name = NonemptyString("*");
  NonemptyString parentName = NonemptyString("*");
  NonemptyString ancestorName = NonemptyString("*");
  
  this(A, B, C)(A name_, B parentName_, C ancestorName_) {
    name = name_;
    parentName = parentName_;
    ancestorName = ancestorName_;
  }
  this(string source) { // eg: source == "* L Q W"
    import std.regex : ctRegex, split;
    scope(success) validateProperties();
    
    if(source.length == 0)
      return;
    
    enum auto whitespaceSplitterRegex = ctRegex!(r"\s+");
    string[] elementStrings = source.split(whitespaceSplitterRegex); // eg: ["*", "L", "Q"]
    
    name = elementStrings[0]; // eg: "*"
    if(elementStrings.length == 1)
      return;
    
    parentName = elementStrings[1]; // eg: "L"
    if(elementStrings.length == 2)
      return;
    
    ancestorName = elementStrings[2]; // eg: "Q"
    
    if(elementStrings.length > 3)
      throw new Exception("Pattern conditional has too many elements " ~ source);
    
  }
  
  this(JSONValue jsonValue) {
    scope(success) validateProperties();
    
    if(jsonValue.type != JSONType.object)
      throw new Exception(q"[Conditional must be an object (ie like: {"name": "...", "parent": "...", "ancestor": "..."}). Note: an empty object is allowed]");
    
    JSONValue[string] conditionalJson = jsonValue.object();
    
    JSONValue* nameJson = "name" in conditionalJson;
    if(nameJson !is null)
      name = nameJson.str();
    
    JSONValue* parentNameJson = "parent" in conditionalJson;
    if(parentNameJson !is null)
      parentName = parentNameJson.str();
      
    JSONValue* ancestorNameJson = "ancestor" in conditionalJson;
    if(ancestorNameJson !is null)
      parentName = ancestorNameJson.str();
    
  }
  
  
  
  private void validateProperties() {
    import lib: isAlphanumWord;
    if(!isVersion!"noValidation") {
      import lib: isAlphanumWord;
      if(!isAlphanumWord(name) && name != "*")
        throw new Exception("This name \"" ~ name ~ "\" has forbidden characters, allowed characters are: a-z A-Z 0-9");
      if(!isAlphanumWord(parentName) && parentName != "*")
        throw new Exception("Parent name \"" ~ parentName ~ "\" has forbidden characters, allowed characters are: a-z A-Z 0-9");
      if(!isAlphanumWord(ancestorName) && ancestorName != "*")
        throw new Exception("Ancestor name \"" ~ ancestorName ~ "\" has forbidden characters, allowed characters are: a-z A-Z 0-9");
    }
  }
  
  bool matches(String)(String[] contextNames) {
    if((parentName != "*") && (contextNames[$-1] == parentName))
      return true;
    if(ancestorName == "*")
      return true;
    foreach_reverse(String context; contextNames) {
      if(context == ancestorName)
        return true;
    }
    return false;
  }
}

unittest { // conditional matching
  auto conditional = PatternConditional("this", "parent", "1");
  string[] testContext = ["other", "1", "parent"];
  mixin(assertString("conditional.matches(testContext)", "conditional", "testContext"));
  testContext = ["other", "parent", "1"];
  mixin(assertString("conditional.matches(testContext)", "conditional", "testContext"));
  testContext = ["parent", "1", "other"];
  mixin(assertString("conditional.matches(testContext)", "conditional", "testContext"));
  testContext = ["parent", "2", "other"];
  mixin(assertString("!conditional.matches(testContext)", "conditional", "testContext"));
  testContext = ["other", "other", "2", "parent"];
  mixin(assertString("conditional.matches(testContext)", "conditional", "testContext"));
  testContext = ["A", "B", "C"];
  mixin(assertString("!conditional.matches(testContext)", "conditional", "testContext"));
}

struct PatternOrSeq {
  PatternAndSeq[] andSeqs;
  alias andSeqs this;
  
  invariant {
    mixin(assertString("andSeqs.length > 0", "andSeqs.length", "andSeqs"));
  }
  
  this(PatternAndSeq[] andSeqs_) {
    andSeqs = andSeqs_;
  }
  this(string source) { // eg: source == "A-B:b C:c"
    import std.regex : ctRegex, split;
    
    enum auto whitespaceSplitterRegex = ctRegex!(r"\s+");
    string[] elementStrings = source.split(whitespaceSplitterRegex); // eg: ["A-B:b", "C:c"]
    
    foreach(string elementString; elementStrings) { // eg: elementString == "A:a-B:b"
      enum auto elementSplitterRegex = ctRegex!("-");
      string[] elementParts = elementString.split(elementSplitterRegex); // eg: ["A:a", "B:b"]
      
      andSeqs ~= PatternAndSeq(elementParts); // andSeqs looks just like [PatternAtom("A", "a"), PatternAtom("B", "b")]
    }
  }
  
  this(JSONValue jsonValue) {
    if(jsonValue.type != JSONType.array)
      throw new Exception("Or sequence must be an an array of arrays (ie like: [[...], [...], ...]); In or sequence json \"" ~ jsonValue.toString() ~ "\"");
    
    JSONValue[] orSeqJson = jsonValue.array();
    
    foreach(JSONValue andSeqJson; orSeqJson)
      andSeqs ~= PatternAndSeq(andSeqJson).appendToExceptions("In or sequence \"" ~ jsonValue.toString() ~ "\"");
  }
  
  PatternAndSeq* findAndSeq(LV)(LV[] labeledValues) {
    foreach(ref PatternAndSeq seq; andSeqs) {
      if(seq.matches!LV(labeledValues))
        return &seq;
    }
    return null;
  }
}

struct PatternAndSeq {
  PatternAtom[] atoms;
  alias atoms this;
  
  invariant {
    mixin(assertString("atoms.length > 0", "atoms.length", "atoms"));
  }
  
  this(PatternAtom[] atoms_) {
    atoms = atoms_;
  }
  this(string[] elementParts) { // eg: elementParts == ["A:a", "B:b"]
    foreach(string unsplitAtom; elementParts)
      atoms ~= PatternAtom(unsplitAtom);
  }
  
  this(JSONValue jsonValue) {
    if(jsonValue.type != JSONType.array)
      throw new Exception(q"[And sequence must be an an array of strings (ie like: ["A", "B", ...])]" ~ " In and sequence json " ~ jsonValue.toString());
    
    JSONValue[] andSeqJson = jsonValue.array();
    
    foreach(JSONValue atomJson; andSeqJson)
      atoms ~= PatternAtom(atomJson);
  }
    
  bool matches(LV)(LV[] labeledValues) {
    if(labeledValues.length < atoms.length)
      return false;
    ulong i = labeledValues.length-1;
    ulong j = atoms.length - 1;
    while(true) {
      LV currentValue = labeledValues[i];
      PatternAtom currentAtom = atoms[j];
      if(!currentAtom.matches!LV(currentValue))
        return false;
      if(i == 0 || j == 0)
        break;
      i--; j--;
    }
    return true;
  }
}

struct PatternAtom {
  NonemptyString label = NonemptyString("*");
  NonemptyString value = NonemptyString("*");
  
  this(A, B)(A label_, B value_) {
    label = label_;
    value = value_;
  }
  
  void checkSide(string side) {
    if(side.length == 0)
      throw new Exception("Atom cannot have empty side before or after ':' symbol (use * instead of nothing)");
  }
  
  this(string unsplitAtom) { // eg: unsplitAtom == "A:a"
    import std.regex : ctRegex, split;
    
    enum auto atomSplitterRegex = ctRegex!(":");
    string[] atomComponents = unsplitAtom.split(atomSplitterRegex); // eg: ["A", "a"]
    version(assert) mixin(assertString("atomComponents.length > 0"));
    
    checkSide(atomComponents[0]).appendToExceptions("In atom \"" ~ unsplitAtom ~ "\"");
    label = atomComponents[0]; // eg: A
    
    if(atomComponents.length > 1) {
      checkSide(atomComponents[1]).appendToExceptions("In atom \"" ~ unsplitAtom ~ "\"");
      value = atomComponents[1]; // eg: a
    } else if(atomComponents.length > 2){
      throw new Exception("Atom " ~ unsplitAtom ~ " has too many ':' symbols (should only be 1)");
    }
  }
  
  
  this(JSONValue jsonValue) {
    scope(success) validateProperties();
    
    if(jsonValue.type == JSONType.array) {
      JSONValue[] atomJsonArray = jsonValue.array();
      
      if(atomJsonArray.length == 0)
        return;
      
      JSONValue labelJson = atomJsonArray[1];
      if(labelJson.type != JSONType.string)
        throw new Exception("Atom label (1st element) isn't a string" ~ ". In json value " ~ labelJson.toString() ~ ". In atom json " ~ jsonValue.toString());
      label = labelJson.str();
      
      if(atomJsonArray.length == 1)
        return;
      
      JSONValue valueJson = atomJsonArray[1];
      if(valueJson.type != JSONType.string)
        throw new Exception("Atom value (2nd element) isn't a string" ~ ". In json value " ~ valueJson.toString() ~ ". In atom json " ~ jsonValue.toString());
      label = valueJson.str();
      
    } else if (jsonValue.type == JSONType.string) {
      label = jsonValue.str();
    } else {
      throw new Exception("Atom json must be an array with two strings, or a string. In atom json " ~ jsonValue.toString());
    }
    
  }
  
  private void validateProperties() {
    static if(!isVersion!"noValidation") {
      import lib: isAlphanumWord;
      if(!isAlphanumWord(label) && label != "*")
        throw new Exception("Label \"" ~ label ~ "\" has forbidden characters, allowed characters are: a-z A-Z 0-9");
      if(!isAlphanumWord(value) && value != "*")
        throw new Exception("Value \"" ~ value ~ "\" has forbidden characters, allowed characters are: a-z A-Z 0-9");
    }
  }
  
  bool matches(LV)(LV labeledValue) {
    string testLabel = labeledValue.label;
    string testValue = labeledValue.value;
    if((label != "*") && (testLabel != label))
      return false;
    if((value != "*") && (testValue != value))
      return false;
    return true;
  }
}

unittest { // atom matching
  struct LV {
    string label;
    string value;
  }
  auto atom = PatternAtom("*", "*");
  mixin(assertString(q"[atom.matches(LV("Abc", "xyz"))]"));
  atom = PatternAtom("A", "*");
  mixin(assertString(q"[!atom.matches(LV("Abc", "xyz"))]"));
  mixin(assertString(q"[atom.matches(LV("A", "xyz"))]"));
  mixin(assertString(q"[atom.matches(LV("A", "qwe"))]"));
  atom = PatternAtom("A", "a");
  mixin(assertString(q"[!atom.matches(LV("Abc", "xyz"))]"));
  mixin(assertString(q"[!atom.matches(LV("A", "xyz"))]"));
  mixin(assertString(q"[atom.matches(LV("A", "a"))]"));
}

// -------------

import tree: TreeBody, NodeBody, TreeIndex;

// 9fa3ed63-ac89-568c-a7ae-14be4de461c7
struct RangeNode {
  mixin NodeBody!();
  string patternName = ""; // pattern name distiguishing this range
  ulong start = 0; // opener position in labeledValues array
  ulong end   = 0; // closer position
  
  this(Args...)(Args args) {
    static if(Args.length > 3)
      static assert(0, "Too many arguments for RangeNode constructor");
    bool startSet = false;
    static foreach(arg; args) {
      static if(is(typeof(arg) == string)) {
        patternName = arg;
      } else static if(is(typeof(arg) == ulong)) {
        if(!startSet) {
          start = arg;
          startSet = true;
        } else {
          end = arg;
        }
      } else {
        static assert(0, "RangeNode constructor can't take this arg type " ~ typeof(arg).stringof);
      }
    }
  }
  
  JSONValue toJson() {
    return JSONValue(["start": JSONValue(start), "end": JSONValue(end), "name": JSONValue(patternName)]);
  }
}

// 9fa3ed63-ac89-568c-a7ae-14be4de461c7
struct RangeTree {
  mixin TreeBody!RangeNode;
}

// 565ceed2-a886-5a1c-97d3-85f50321de73
struct LabeledValue {
  string label;
  string value;
  
  static LabeledValue fromLine(string source) {
    import lib: splitAtFirst;
    import std.string: strip;
    
    string line = source.strip();
    
    string[2] labelAndValue = line.splitAtFirst!":"; // note: no : on line is eq to empty rhs
    
    string newLabel = labelAndValue[0].strip();
    string newValue = labelAndValue[1].strip();
    if(newLabel.length == 0)
      throw new Exception("Line \"" ~ line ~ "\": label (left hand side) is empty");
    
    return LabeledValue(newLabel, newValue);
  }
  
  static LabeledValue[] seqFromLineSeq(string source) {
    import std.regex: ctRegex, split;
    import std.string: strip;
    
    LabeledValue[] ret;
    
    enum auto lineSeparatorRegex = ctRegex!r"\s*\n\s*";
    
    ulong lineNumber = 0;
    string[] unstrippedLineSeq = source.split(lineSeparatorRegex);
    foreach(string unstrippedLine; unstrippedLineSeq) {
      import lib : appendToExceptions;
      import std.conv : to;
      appendToExceptions((){
        LabeledValue newLabeledValue = LabeledValue.fromLine(unstrippedLine);
        newLabeledValue.validateProperties();
        ret ~= newLabeledValue;
      }(), "On line number " ~ lineNumber.to!string);
      lineNumber++;
    }
    
    return ret;
  }
  
  static LabeledValue fromJson(JSONValue jsonSource) {
    if(jsonSource.type == JSONType.array) {
      JSONValue[] sourceAsArray = jsonSource.array;
      
      if(sourceAsArray.length != 2)
        throw new Exception("LabeledValue json item \"" ~ jsonSource.toString() ~"\" has too few items");
      
      if(sourceAsArray[0].type != JSONType.string)
        throw new Exception("LabeledValue json item \"" ~ jsonSource.toString() ~"\" element 1 (label element) must be a string");
      if(sourceAsArray[1].type != JSONType.string)
        throw new Exception("LabeledValue json item \"" ~ jsonSource.toString() ~"\" element 2 (value element) must be a string");
      
      string labelString = sourceAsArray[0].str();
      string valueString = sourceAsArray[1].str();
      auto ret = LabeledValue(labelString, valueString);
      ret.validateProperties();
      return ret;
    } else if(jsonSource.type == JSONType.object) {
      JSONValue[string] sourceAsObject = jsonSource.object();
      
      JSONValue* maybeLabelJson = "label" in sourceAsObject;
      JSONValue* maybeValueJson = "value" in sourceAsObject;
      if(maybeLabelJson is null)
        throw new Exception("LabeledValue json item \"" ~ jsonSource.toString() ~ "\" has no 'label' property");
      if(maybeValueJson is null) {
        maybeValueJson = "partition" in sourceAsObject; // for compatibility with progressive partition
        if(maybeValueJson is null)
          throw new Exception("LabeledValue json item \"" ~ jsonSource.toString() ~ "\" has no 'value' or 'partition' properties");
      }
      
      JSONValue labelJson = *maybeLabelJson;
      JSONValue valueJson = *maybeValueJson;
      
      if(labelJson.type != JSONType.string)
        throw new Exception("LabeledValue json item \"" ~ jsonSource.toString() ~"\" label element must be a string");
      if(valueJson.type != JSONType.string)
        throw new Exception("LabeledValue json item \"" ~ jsonSource.toString() ~"\" value element must be a string");
      
      string labelString = labelJson.str();
      string valueString = valueJson.str();
      auto ret = LabeledValue(labelString, valueString);
      ret.validateProperties();
      return ret;
    } else {
      throw new Exception("LabeledValue json item \"" ~ jsonSource.toString() ~"\" is an unrecognized type (should be an array [...] with two items, or an object {...} with 'label' and 'value' properties)");
    }
  }
  
  static LabeledValue[] seqFromJson(JSONValue seqJson) {
    import lib : appendToExceptions;
    import std.conv : to;
    
    if(seqJson.type != JSONType.array)
      throw new Exception("LabeledValue json source must be an array");
    
    LabeledValue[] ret;
    foreach(ulong itemNumber, JSONValue labelAndValueJson; seqJson.array()) {
      ret ~= appendToExceptions( LabeledValue.fromJson(labelAndValueJson), "At item number " ~ itemNumber.to!string);
    }
    return ret;
  }
  
  void validateProperties() {
    static if(!isVersion!"noValidation") {
      if(label.length == 0)
        throw new Exception("LabeledValue label is empty");
    }
  }
}

// df825834-21e9-5494-beb2-2ee7dbcabdae
RangeTree buildRangeTree(LV)(PatternSystem patternSystem, LV[] labeledValues, bool closeImplicitly = false) {
  import lib: Stack;
  
  RangeTree retTree;
  retTree.addRoot(0uL, ulong(labeledValues.length-1));
  
  ulong activeIndex = 0; // labeled value position
  TreeIndex activeNodeIndex = retTree.rootIndex;
  Pattern* activePattern = null;
  ulong activeOpenerIndex;
  Stack!string patternNameStack; // this is just to send into Pattern.searchOpeners
  Stack!(Pattern*) patternStack; // this is so we can return to previous activePatterns
  Stack!ulong  openerIndexStack; // primarily for debugging
  
  // go through whole labeledValues, new node on found opener, back to parent node on found closer
  // we're recording the opener and closer positions (ie: pattern ranges) in the RangeTree
  while(true) {
    bool hasActivePattern = (activePattern !is null);
    
    // are we at the end of labeledValues?
    if(activeIndex >= labeledValues.length) {
      // are we searching for closers?
      if(!hasActivePattern)
        break; // don't need to do anything, just return
      
      // close all the closers or throw exception
      if(closeImplicitly) {
        // go through and set all the range ends up to root of tree
        TreeIndex nodeIndex = activeNodeIndex;
        while(nodeIndex != retTree.rootIndex) {
          RangeNode* node = &retTree.get(nodeIndex);
          node.end  = labeledValues.length - 1;
          nodeIndex = node.parentIndex;
        }
      } else { // report the active openers
        import std.conv : to;
        ulong[] openerIndices;
        LV[] openerLvs;
        foreach(ulong index; openerIndexStack) {
          openerIndices ~= index;
          openerLvs ~= labeledValues[index];
        }
        openerIndices ~= activeOpenerIndex;
        openerLvs ~= labeledValues[activeOpenerIndex];
        throw new Exception(
          "Reached end of labeledValues array without finding closers\n" ~
          "  opener indices: " ~ openerIndices.to!string ~ "\n" ~
          "  opener LVs:     " ~ openerLvs.to!string
        );
      }
      break;
    }
    
    LV[] activeLabeledValueSlice = labeledValues[0 .. activeIndex+1]; // for sending into search functions
    
    if(hasActivePattern) {
      // can we close the active pattern?
      PatternAndSeq* foundAndSeq = activePattern.closers.findAndSeq(activeLabeledValueSlice);
      if(foundAndSeq !is null) {
        // found closer, so close
        
        // set proper end of active node's range
        RangeNode* activeElement = &retTree.get(activeNodeIndex);
        activeElement.end = activeIndex;
        
        // pop last search state
        if(patternStack.isEmpty) {
          activePattern = null;
          activeNodeIndex = retTree.rootIndex;
        } else {
          patternNameStack.pop();
          activePattern = patternStack.pop();
          activeOpenerIndex = openerIndexStack.pop();
          activeNodeIndex = activeElement.parentIndex;
        }
        
        activeIndex++;
        continue;
      }
    }
    // didn't find a closer...
    
    // can we open a new pattern?
    PatternSystem.SearchResult openerSearchResult = patternSystem.searchOpeners(patternNameStack, activeLabeledValueSlice);
    if(openerSearchResult.found) {
      // lv slice matches an opener, so open that pattern
      if(hasActivePattern) {
        patternNameStack.push(activePattern.conditional.name);
        patternStack.push(activePattern);
        openerIndexStack.push(activeOpenerIndex);
      }
      
      activeOpenerIndex = activeIndex;
      activePattern     = openerSearchResult.patternRef;
      string patternName = activePattern.conditional.name;
      activeNodeIndex   = retTree.appendChild(activeNodeIndex, patternName, activeIndex);
      // Note: we set just the start of the new node's range, we'll set end on close
      
      activeIndex++;
      continue;
    }
    // didn't find an opener
    
    activeIndex++;
    continue; 
  }
  
  return retTree;
}

unittest {
  struct LV {
    string label;
    string value;
  }
  auto patternSystem = PatternSystem("A B > C D\n X Y > Z W");
  LV[] labeledValues = [
    LV("A", "a"),
    LV("Y", "y"),
    LV("Z", "z"),
    LV("C", "c")
  ];
  
  RangeTree tree = buildRangeTree(patternSystem, labeledValues);
  
  ulong[2][] rangeTraversal;
  tree.applyDeepestChildrenFirst(tree.rootIndex, (TreeIndex index) {
    RangeNode rangeNode = tree.get(index);
    rangeTraversal ~= [rangeNode.start, rangeNode.end];
  });
  ulong[2][] correctRangeTraversal = [[1, 2], [0, 3], [0, 3]]; // last [0, 3] from root, which has that by default
  mixin(assertString("rangeTraversal == correctRangeTraversal", "rangeTraversal"));
}

//


// 31cf8c6d-47ca-5336-be61-b2b487e7fd43
static if(isVersion!"rangeTreeBuilderMain") {
  import std.stdio : writeln, stdin, stdout, File;
  import std.algorithm : endsWith;
  import lib: readEntireFile, escapeJsonHazardousCharacters, appendToExceptions;
  
  int main(string[] args) { try {
    
    string patternFileName = ""; // empty -> try reading both ./range_patterns.json and ./range_patterns.txt
    string inputFileName   = ""; // empty -> use stdin
    string outputFileName  = ""; // empty -> use stdout
    bool linesInput = false;
    bool prettyJson = false;
    
    import std.getopt; // https://devdocs.io/d/std_getopt for command line arguments
    auto helpInformation = getopt(
      args,
      "patterns|p",
          "Range pattern file (defaults to ./range_patterns.json or ./range_patterns.txt, whichever is found first). See range_tree_builder.md for format",
          &patternFileName,
      "input|i",
          "Input file with string to partition (defaults to stdin). Stdin is interpreted as json unless the --lineseq / -l switch is given\nText files are interpreted automatically as a sequence of lines with ':' (colon) as separator between labels and values on each line",
          &inputFileName,
      "lineseq|l",
          "This switch makes stdin be interpreted like a txt file, instead of as json, see --input above",
          &linesInput,
      "output|o",
          "File to put json output in (defaults to stdout)",
          &outputFileName,
      "verbose|v",
          "Print what the program is doing",
          (string _name, string _value) {
            verbosity = Verbosity.from("steps");
          },
      "verbosity|V",
          "Can be either none or 0 (default), steps or 1 (report major process steps), all or 2",
          (string _name, string verbositySetting) {
            import lib : appendToExceptions;
            if(verbositySetting == "0")
              verbosity = Verbosity.from("none");
            if(verbositySetting == "1")
              verbosity = Verbosity.from("steps");
            if(verbositySetting == "2")
              verbosity = Verbosity.from("all");
            else
              verbosity = Verbosity.from(verbositySetting).appendToExceptions("Bad verbosity setting " ~ verbositySetting);
          },
      "pretty|r",
          "Output human-comprehensible json with appropriate newlines and whitespace, instead of json without newliens or whitespace (defaults to false)",
          &prettyJson
    ).appendToExceptions("When parsing command line operations");
    
    // called with --help or -h
    if(helpInformation.helpWanted) {
      import lib: ctConcat;
      writeln("This program builds a tree of ranges out of a sequence of labeled values");
      writeln("See range_tree_builder.md for details how to use it");
      defaultGetoptPrinter("Options:", helpInformation.options);
      return 0;
    }
    
    writeln(
      textGreenFg!"patterns: ", patternFileName, "\n",
      textGreenFg!", input file: ", inputFileName.length == 0 ? "stdin" : inputFileName, "\n",
      textGreenFg!", output file: ", outputFileName.length == 0 ? "stdout" : outputFileName, "\n",
      textGreenFg!", verbosity: ", verbosity, "\n"
    ).when(verbosity.atLeast!"all");
    
    // open and read pattern file
    writeln("Opening and reading pattern files...").when(verbosity.atLeast!"steps");
    File patternFile;
    string patternData;
    // use default pattern file?
    if(patternFileName.length == 0) { // use default
      import std.file : exists;
      writeln("  Using default pattern file").when(verbosity.atLeast!"all");
      if(exists("./range_patterns.json")) {
        writeln("    Using ./range_patterns.json").when(verbosity.atLeast!"all");
        patternFileName = "./range_patterns.json";
      } else if(exists("./range_patterns.txt")) {
        writeln("    Using ./range_patterns.txt").when(verbosity.atLeast!"all");
        patternFileName = "./range_patterns.txt";
      } else {
        throw new Exception("No pattern file given with --pattern, and no default ./range_patterns.json or ./range_patterns.txt found");
      }
    }
    // open
    writeln("Opening pattern file").when(verbosity.atLeast!"all");
    patternFile = File(patternFileName, "r").appendToExceptions("While trying to open pattern file");
    // read
    writeln("Reading pattern file").when(verbosity.atLeast!"all");
    patternData = readEntireFile(patternFile).appendToExceptions("While trying to read pattern file");
    writeln("Closing").when(verbosity.atLeast!"all");
    patternFile.close();
    
    // open and read input file
    writeln("Opening and reading input file").when(verbosity.atLeast!"steps");
    File inputFile;
    string inputData;
    // open
    if(inputFileName.length > 0) {
      writeln("  Opening input file").when(verbosity.atLeast!"all");
      inputFile = File(inputFileName, "r").appendToExceptions("While trying to open input file");
      if(!inputFileName.endsWith(".json")) {
        writeln("  Treating as plaintext").when(verbosity.atLeast!"all");
        linesInput = true;
      }
    } else {
      writeln("  Using stdin").when(verbosity.atLeast!"all");
      inputFile = stdin;
    }
    // read
    writeln("Reading input").when(verbosity.atLeast!"all");
    inputData = readEntireFile(inputFile).appendToExceptions("While trying to read input file");
    writeln("Closing input").when(verbosity.atLeast!"all");
    if(inputFile != stdin)
      inputFile.close();
    
    // open output file
    writeln("Opening output file").when(verbosity.atLeast!"steps");
    File outputFile;
    scope(exit) {
      if(outputFile != stdout)
        outputFile.close();
    }
    if(outputFileName.length > 0) {
      writeln("  Not using stdout").when(verbosity.atLeast!"all");
      outputFile = File(outputFileName, "w").appendToExceptions("While trying to open output file");
    } else {
      writeln("  Using stdout").when(verbosity.atLeast!"all");
      outputFile = stdout;
    }
    
    // build the pattern system:
    writeln("Building the pattern system").when(verbosity.atLeast!"steps");
    PatternSystem patternSystem;
    // is pattern file custom format or json?
    if(patternFileName.endsWith(".json")) {
      import std.json: parseJSON;
      
      writeln("  Parsing json pattern file").when(verbosity.atLeast!"all");
      JSONValue patternFileJson = parseJSON(patternData).appendToExceptions("While trying to parse json pattern file \"" ~ patternFileName ~ "\"");
      
      writeln("  Making the PatternSystem object").when(verbosity.atLeast!"all");
      patternSystem = PatternSystem(patternFileJson).appendToExceptions("While trying to make pattern system from json");
    } else { // pattern file is custom format 
    
      writeln("  Making the PatternSystem from plaintext").when(verbosity.atLeast!"all");
      patternSystem = PatternSystem(patternData).appendToExceptions("While trying to make pattern system from pattern file contents");
    }
    
    // parse the input
    writeln("Parsing the input").when(verbosity.atLeast!"steps");
    LabeledValue[] labeledValueSeq;
    if(linesInput) { // input is sequence of lines
      writeln("  Parsing input as plaintext").when(verbosity.atLeast!"all");
      labeledValueSeq = LabeledValue.seqFromLineSeq(inputData).appendToExceptions("While trying to parse input line sequence");
    } else { // input is json
      import std.json: parseJSON;
      writeln("  Parsing input as json").when(verbosity.atLeast!"all");
      writeln("    Parsing json").when(verbosity.atLeast!"all");
      JSONValue inputJson = parseJSON(inputData).appendToExceptions("While trying to parse input json");
      writeln("    making LabeledValue from json").when(verbosity.atLeast!"all");
      labeledValueSeq = LabeledValue.seqFromJson(inputJson);
    }
    
    // make output tree
    writeln("Making output tree").when(verbosity.atLeast!"steps");
    RangeTree outputTree;
    outputTree = buildRangeTree(patternSystem, labeledValueSeq).appendToExceptions("While trying to build range tree");
    
    writeln("Converting output tree to json").when(verbosity.atLeast!"all");
    JSONValue outputTreeJson = outputTree.toJson();
    
    // write the output to output file
    writeln("Writing to output file ", outputFileName.length == 0 ? "stdout" : outputFileName).when(verbosity.atLeast!"all");
    outputFile.write(prettyJson ? outputTreeJson.toPrettyString() : outputTreeJson.toString());
    
    return 0;
  } catch(Exception exc) {
    writeln(exc.msg);
    return 1;
  }}
}
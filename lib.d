module lib;


// 364c8f85-49a7-54cb-955b-d8c44091a701
template from(string mod) {
  mixin("import from = " ~ mod ~ ";"); // eg: import from = std.stdio;
}
unittest {
  string res = from!"std.array".replace("xyyx", "y", "x");
  mixin(assertString(q"[ res == "xxxx" ]"));
}

// 8dafd46c-75f8-542d-a335-3e3d1a9b1f55
enum bool hasModule(string modName) = !isVersion!(ctConcat!("noModule_", ctReplace!(modName, ".", "_"))) && __traits(compiles, from!modName);

// 107b6052-6d0e-5d72-a977-a2f974e53b34
struct Stack(T) {
  T[] arrayForm;
  alias arrayForm this;
  
  bool isEmpty() {
    return arrayForm.length == 0;
  }
  
  Maybe!T popSafe() {
    if(arrayForm.length > 0)
      return Maybe!T(pop());
    else
      return Maybe!T.invalid;
  }
  T pop() {
    T ret = arrayForm[$-1];
    arrayForm.length--;
    return ret;
  }
  
  Maybe!T peekSafe() {
    if(arrayForm.length > 0)
      return Maybe!T(peek());
    else
      return Maybe!T.invalid;
  }
  T peek() {
    return arrayForm[$-1];
  }
  
  void push(T value) {
    arrayForm ~= value;
  }
}
unittest {
  Stack!int s;
  s.push(1);
  s.push(2);
  s.push(3);
  mixin(assertString("!s.isEmpty", "s"));
  
  int p = s.pop;
  mixin(assertString("p == 3", "p", "s"));
  p = s.pop;
  mixin(assertString("p == 2", "p", "s"));
  
  Maybe!int mp = s.popSafe;
  mixin(assertString("mp.valid", "mp", "s"));
  mixin(assertString("mp == 1", "mp", "s"));
  
  mixin(assertString("s.isEmpty", "s"));
  
  mp = s.popSafe;
  mixin(assertString("!mp.valid", "s"));
}

// e35ddfb7-96a4-5e73-b846-9883d693bf80
struct TwoEndedStack(T) {
  T[] arrayForm;
  
  ulong start, end;
  ulong length;
  
  invariant {
    mixin(assertString("iff(start == end, length <= 1)", "start", "end", "length", "arrayForm.length", "this"));
    mixin(assertString("(start < arrayForm.length) || (arrayForm.length == 0)", "start", "end", "arrayForm.length", "this"));
    mixin(assertString("(end < arrayForm.length) || (arrayForm.length == 0)", "start", "end", "arrayForm.length", "this"));
  }
  
  this(ulong n) {
    arrayForm.length = n > 1 ? n : 1;
  }
  
  ref T opIndex(ulong index) { return arrayForm[index]; }
  
  T[] asArray() {
    T[] ret;
    ulong i = start;
    while(true) {
      ret ~= arrayForm[i];
      
      if(i == end)
        break;
      increment(i);
    }
    return ret;
  }
  
  private void increaseSize() {
    ulong oldArrayLength = arrayForm.length;
    arrayForm.length = (arrayForm.length + 1) * 2;
    if(start > end) {
      // move elements from start to new end of array
      ulong iNew = arrayForm.length-1;
      ulong iOld = oldArrayLength-1;
      while(true) {
        arrayForm[iNew] = arrayForm[iOld];
        
        if(iOld == start)
          break;
        iNew--;
        iOld--;
      }
      start = iNew;
    }
  }
  private bool isFull() {
    return (length == arrayForm.length);
  }
  bool isEmpty() {
    return (length == 0);
  }
  
  private void increment(ref ulong side) {
    side++;
    if(side >= arrayForm.length)
      side = 0;
  }
  private void decrement(ref ulong side) {
    if(side == 0)
      side = arrayForm.length - 1;
    else
      side--;
  }
  
  void pushEnd(T value) {
    if(isFull)
      increaseSize();
    length++;
    if(length > 1)
      increment(end);
    arrayForm[end] = value;
  }
  void pushStart(T value) {
    if(isFull)
      increaseSize();
    length++;
    if(length > 1)
      decrement(start);
    arrayForm[start] = value;
  }
  
  T popEnd() {
    T ret = arrayForm[end];
    length--;
    decrement(end);
    if(length == 0) {
      start = 0;
      end = 0;
    }
    return ret;
  }
  T popStart() {
    T ret = arrayForm[start];
    length--;
    increment(start);
    if(length == 0) {
      start = 0;
      end = 0;
    }
    return ret;
  }
  
  Maybe!T popEndSafe() {
    if(length == 0)
      return Maybe!T.invalid;
    else
      return Maybe!T(popEnd());
  }
  Maybe!T popStartSafe() {
    if(length == 0)
      return Maybe!T.invalid;
    else
      return Maybe!T(popStart());
  }
  
  T peekEnd() {
    return arrayForm[end];
  }
  T peekStart() {
    return arrayForm[start];
  }
  
  Maybe!T peekEndSafe() {
    if(length == 0)
      return Maybe!T.invalid;
    else
      return Maybe!T(peekEnd());
  }
  Maybe!T peekStartSafe() {
    if(length == 0)
      return Maybe!T.invalid;
    else
      return Maybe!T(peekStart());
  }
}
unittest {
  auto stack = TwoEndedStack!int(3);
  stack.pushEnd(3);
  stack.pushEnd(5);
  stack.pushEnd(7);
  stack.pushEnd(11);
  mixin(assertString("stack.length == 4", "stack.length", "stack"));
  
  int val;
  
  val = stack.popStart();
  mixin(assertString("stack.length == 3", "stack.length", "stack"));
  mixin(assertString("val == 3", "val", "stack"));
  
  val = stack.popEnd();
  mixin(assertString("stack.length == 2", "stack.length", "stack"));
  mixin(assertString("val == 11", "val", "stack"));
  
  stack.pushEnd(13);
  stack.pushEnd(17);
  mixin(assertString("stack.length == 4", "stack.length", "stack"));
  
  val = stack.popStart();
  mixin(assertString("stack.length == 3", "stack.length", "stack"));
  mixin(assertString("val == 5", "val", "stack"));
  
  int[] array = stack.asArray;
  mixin(assertString("array == [7, 13, 17]", "array", "stack"));
  // should be literally TwoEndedStack!int([3, 5, 7, 13, 17, 0], 2, 4, 3) here
  
  // following forces a resize with start > end (ie: requires moving elements to end of arrayForm on resize)
  stack.pushEnd(19);
  stack.pushEnd(23);
  stack.pushEnd(29);
  mixin(assertString("stack.asArray == [7, 13, 17, 19, 23, 29]", "stack.asArray", "stack"));
  
  stack.pushStart(31);
  stack.pushStart(37);
  stack.pushStart(41);
  mixin(assertString("stack.asArray == [41, 37, 31, 7, 13, 17, 19, 23, 29]", "stack.asArray", "stack"));
}

unittest {
  import std.random : uniform;
  
  TwoEndedStack!int stack;
  int[] correctArray;
  
  enum ulong count = cast(ulong)10e2;
  for(ulong i = 0; i < count; i++) {
    int num = uniform(0, cast(int)10e6);
    if(uniform(0.0f, 1.0f) < 0.5) {
      stack.pushEnd(num);
      correctArray ~= num;
    } else {
      stack.pushStart(num);
      correctArray = num ~ correctArray;
    }
  }
  
  mixin(assertString("stack.length == correctArray.length", "stack", "correctArray"));
  mixin(assertString("stack.asArray == correctArray", "stack", "correctArray"));
}

// dbb7e8b4-dc97-5875-b78a-67c7d6d5e9c8
struct Maybe(T) {
  alias This = typeof(this);
  
  T value;
  alias value this;
  
  static if(isNullable!T) { // a pointer
    // Maybe!T in pointer mode is just its value
    
    bool valid() { return value !is null; }
    
    static This invalid() {
      return This();
    }
    
    
  } else { // not a pointer
    // Maybe!T in not-pointer mode is its value plus a proxy for a null state
    
    this(T value_) {
      value = value_;
      valid = true;
    }
    
    bool valid = false;
    
    static This invalid() {
      return This();
    }
    
    static immutable string maybeTypeStringStart = "Maybe!" ~ T.stringof ~ "(";
    static immutable string maybeTypeStringInvalid = "Maybe!" ~ T.stringof ~ ".invalid";
    string toString() {
      import std.conv : to;
      if(valid)
        return maybeTypeStringStart ~ value.to!string ~ ")";
      else
        return maybeTypeStringInvalid;
    }
  }
}
unittest {
  class Cla { int x; }
  auto cla = new Cla;
  Maybe!Cla maybeCla;
  mixin(assertString("!maybeCla.valid"));
  maybeCla = cla;
  mixin(assertString("maybeCla.valid"));
}

// 69159255-e312-5d36-8b49-73bd26b827da
struct NonemptyString {
  string stringForm;
  alias stringForm this;
  
  this(NonemptyString nes) {
    stringForm = nes.stringForm;
  }
  this(string str) {
    stringForm = str;
  }
  
  invariant {
    mixin(assertString("stringForm.length > 0", "stringForm.length", "stringForm"));
  }
}
// 89bd62f7-571e-5e64-ab15-587500581c8a
enum NonemptyString[] makeNonempty(string[] array) = (){
  NonemptyString[] ret = [];
  foreach(string str; array)
    ret ~= NonemptyString(str);
  return ret;
}();

unittest {
  void takesString(String)(String str) {
    string myString = str;
    //
  }
  takesString("asdf");
  takesString(NonemptyString("asdf"));
}


// 443af432-a1eb-5e49-94cd-942d123fb1c7
enum T[] literalAs(T, alias array) = (){
  T[] ret;
  foreach(elem; array)
    ret ~= cast(T)elem;
  return ret;
}();
unittest {
  NonemptyString[] strs = literalAs!(NonemptyString, ["asdf", "xyzw"]);
  mixin(assertString(q"[ strs == ["asdf", "xyzw"] ]"));
}

// e44747b8-5e5d-57b6-a099-4904d0c22d8f
struct DebugEmpty { }
enum auto debugValue(alias value) = (){
  debug {
    return value;
  } else {
    return DebugEmpty();
  }
}();
template DebugType(T) {
  debug
    alias DebugType = T;
  else
    alias DebugType = DebugEmpty;
}

// 9716cf05-325c-5f2c-9de3-9f784c0966d1
bool iff(bool a, bool b) {
  return (a == b);
}

// 01efa8ec-74ed-5334-933c-c48a49e4bc83
T echo(T)(T value, uint line = __LINE__) {
  import std.stdio;
  writeln(line, " echo: ", value);
  return value;
}

// 0afc45ec-1e3f-55b0-95c7-9b41cbf15f0b
enum bool writeAllStackLines = false;
void writeStack() {
  import core.runtime: defaultTraceHandler, defaultTraceDeallocator;
  import core.stdc.stdio: printf;
  
  auto trace = defaultTraceHandler(null);
  foreach(line; trace) {
    if(writeAllStackLines || line.ptr[0] != '?')
      printf("%.*s\n", cast(int)line.length, line.ptr);
  }
  defaultTraceDeallocator(trace);
}

// 4cbbdcd4-6dbf-589f-8b62-bfcceaf64b69
ulong countStackDepth() {
  import core.runtime: defaultTraceHandler, defaultTraceDeallocator;
  
  auto trace = defaultTraceHandler(null);
  ulong depth = 0;
  foreach(line; trace)
    depth++;
  defaultTraceDeallocator(trace);
  return depth;
}

private ulong[string] collectedStacks;
private ulong collectedStacksCallCount = 0;
void dbgCollectStacksAndWriteEvery(ulong writeEvery = 10) {
  import core.runtime : defaultTraceHandler, defaultTraceDeallocator;
  import std.string : format;
  
  auto trace = defaultTraceHandler(null);
  foreach(line; trace) {
    if(writeAllStackLines || line.ptr[0] != '?') {
      string lineStr = format!"%.*s"(cast(int)line.length, line.ptr);
      collectedStacks.update(lineStr, () => 0, (ulong oldCount) => oldCount+1);
    }
  }
  defaultTraceDeallocator(trace);
  
  collectedStacksCallCount++;
  if(collectedStacksCallCount % writeEvery == 0) {
    import std.stdio: writeln;
    foreach(string line, ulong count; collectedStacks)
      writeln(line, " ", redFg, count, noStyle);
  }
}

// 9fd54247-bbce-5385-955d-4a39d3429a5f
string assertString(string msg = "", ulong line = __LINE__, string fnName = __FUNCTION__, string modName = __MODULE__)(string expr, string[] otherStrings...) {
  import std.conv : to;
  string escapedExpr = norEscapeQuotes(expr);
  string ret = "{\n  import std.stdio; import lib : assertString;
  if(!(" ~ expr ~ ")){ // " ~ (line+3).to!string ~ "
    writeln(\"=== Assertion failure, printing stack ===\"); // " ~ (line + 4).to!string ~ "
    writeStack(); // " ~ (line+5).to!string ~ "
    writeln(\"Note: in module "~ modName ~" in function " ~ fnName ~"\"); // " ~ (line+6).to!string ~ "
    writeln(\"Assertion failure on line " ~ boldTxt ~ line.to!string ~ noStyle ~ " for " ~ redFg ~ escapedExpr ~ noStyle ~ "\"); // " ~ (line+7).to!string ~ "
    writeln(\"Other values:\"); // " ~ (line+8).to!string ~ "\n";
  int lineOffset = 0;
  foreach(string str; otherStrings) {
    lineOffset++;
    string escapedStr = norEscapeQuotes(str);
    ret ~= "writeln(\"  " ~ greenFg ~ escapedStr ~ noStyle ~ " == \", " ~ str ~ "); // " ~ (line + 9 + lineOffset).to!string ~"\n";
  }
  return ret ~ "assert(false, \"" ~ msg ~ "\"); // " ~ (line + lineOffset + 10).to!string ~"  \n}\n}";
}
unittest {
  mixin(assertString("1 == 1"));
  mixin(assertString(q"[ ("a" ~ "b") == "ab" ]"));
}

// e1c33342-b5d6-5501-9014-077f6bb433e0
void tracedAssert(bool res, string msg = "") {
  if(res)
    return;
  writeStack();
  assert(res, msg);
}

// 0a8baa0e-bb69-577d-938e-6dac82dc91f3
void dbglnFull(int line = __LINE__, string mod = __MODULE__, string fn = __PRETTY_FUNCTION__) {
  import std.stdio : writeln;
  writeln(line, " (", mod, ":  ", fn, ")");
}
// 20ae8807-f15b-5b2f-ab7c-536bd6c192c8
void dbgln(int line = __LINE__) {
  import std.stdio : writeln;
  writeln(line);
}

// d95131cb-75a9-51bc-b87f-a86db950010b
T dbgEchoFull(int line = __LINE__, string mod = __MODULE__, string fn = __PRETTY_FUNCTION__, T, Args...)(T input, Args extraArgs) {
  import std.stdio : writeln;
  writeln(line, " (", mod, ":  ", fn, ") ", input, extraArgs);
  return input;
}

// 3661b33a-34fb-52ba-b92a-a55f44de4b6d
T dbgEcho(int line = __LINE__, T, Args...)(T input, Args extraArgs) {
  import std.stdio : writeln;
  writeln(line, ": ", input, extraArgs);
  return input;
}

// b16a1820-bc95-54bf-adda-3c0b3bcaff0c
string dbgwritelnFullMixin(int line = __LINE__, string mod = __MODULE__, string fn = __PRETTY_FUNCTION__)(string[] args...) {
  import std.conv : to;
  string ret = "import std.stdio : writeln;\n";
  ret ~= "writeln(\"" ~ 
    line.to!string ~ 
    " (" ~ mod ~ 
    "  " ~ fn ~ 
    "):\");\n";
  foreach(string str; args) {
    ret ~= "writeln(\"  " ~ str ~" == \", " ~ str ~");\n";
  }
  return ret;
}
// b16a1820-bc95-54bf-adda-3c0b3bcaff0c
string dbgwritelnMixin(string msg = "", int line = __LINE__)(string[] args...) {
  import std.conv : to;
  string ret = "import std.stdio : writeln;\n";
  ret ~= "writeln(\"" ~ line.to!string ~ ": " ~ msg ~ "\");\n";
  foreach(string str; args) {
    ret ~= "writeln(\"  " ~ greenFg ~ str ~ noStyle ~" == \", " ~ str ~");\n";
  }
  return ret;
}

// 47536b16-ae51-555d-8e8f-325907bed3b4
struct K {
  string stringForm;
}
string dbgWriteMixin(Args...)(ulong line = __LINE__) {
  import std.format : format;
  import std.stdio: write;
  
  string structureTemplate = q"[  {
    import lib : countStackDepth, redFg, noStyle, greenFg;
    import std.stdio: write;
    ulong depth = countStackDepth() - 1;
    write(redFg);
    for(ulong i = 0; i < depth; i++)
      write("-");
    write(noStyle);
    write(" ", %d, ": ");%s
    write("\n");
  }]"; // parameters: %d line, %s body with write lines
  
  string body = "\n";
  static foreach(i, arg; Args) {
    static if(i > 0)
      body ~= "    write(\"; \");";
    static if(is(typeof(arg) == K))
      body ~= "    write(greenFg, \"%s\", noStyle, \" \", %s );\n".format(arg.stringForm, arg.stringForm);
    else static if(is(typeof(arg) == string))
      body ~= "    write(\"%s\");\n".format(arg);
    else
      body ~= "    write(\"Unknown dbgWriteMixin type: " ~ arg ~ "\");\n";
  }
  
  return structureTemplate.format(line, body);
}

// b167010c-423d-5eeb-b24a-b64cc10b7a4c
void dbgwrite(int line = __LINE__, Args...)(Args args) {
  import std.stdio : writeln;
  writeln(line, ": ", args);
}

// 687579a2-fb95-5903-af0c-e31735688bec
immutable string redFg    = "\033[31m";
immutable string greenFg  = "\033[32m";
immutable string blueFg   = "\033[34m";
immutable string redBg    = "\033[41m";
immutable string greenBg  = "\033[42m";
immutable string blueBg   = "\033[44m";
immutable string boldTxt  = "\033[1m";
immutable string noStyle  = "\033[0m";

// 80c68167-9efb-5508-bff8-af5f534553b6
alias ColorAliasSeq(Args...) = Args;
enum auto textRedFg(alias str)   = ColorAliasSeq!(redFg,   str, noStyle);
enum auto textGreenFg(alias str) = ColorAliasSeq!(greenFg, str, noStyle);
enum auto textBlueFg(alias str)  = ColorAliasSeq!(blueFg,  str, noStyle);
enum auto textRedBg(alias str)   = ColorAliasSeq!(redBg,   str, noStyle);
enum auto textGreenBg(alias str) = ColorAliasSeq!(greenBg, str, noStyle);
enum auto textBlueBg(alias str)  = ColorAliasSeq!(blueBg,  str, noStyle);
enum auto textBold(alias str) = ColorAliasSeq!(boldTxt, str, noStyle);

// c54fc86c-1f0f-51ed-b1ef-fb26e533dc4f
enum bool isNullable(T) = __traits(compiles, T.init is null);
enum bool isNullInit(T) = () {
  static if(__traits(compiles, T.init is null))
    return (T.init is null);
  else
    return false;
} ();
unittest {
  class Cla {}
  struct Sct {}
  mixin(assertString("isNullable!Cla"));
  mixin(assertString("isNullable!(int*)"));
  mixin(assertString("isNullable!(void*)"));
  mixin(assertString("!isNullable!Sct"));
  mixin(assertString("!isNullable!int"));
}

// b76550a2-c711-530b-8a4f-fe39f17476d6
T[] intersect(T)(const(T[]) list1, const(T[]) list2) {
  T[] ret;
  foreach(T e1; list1) {
    foreach(T e2; list2) {
      if(e1 == e2)
        ret ~= e1;
    }
  }
  return ret;
}
unittest {
  int[] list1 = [1, 2, 3];
  int[] list2 = [3, 4, 5];
  int[] inter = intersect(list1, list2);
  mixin(assertString("inter.length == 1", "inter.length", "inter"));
}
unittest {
  int[] list1 = [1, 2, 3];
  int[] list2 = [4, 5, 6];
  int[] inter = intersect(list1, list2);
  mixin(assertString("inter.length == 0", "inter.length", "inter"));
}

// da26d3a3-a730-59c3-8aa9-77cd3c28dc0e
T[] swap(T)(T[] array, ulong index1, ulong index2) {
  T[] ret = array.dup;
  ret[index2] = array[index1];
  ret[index1] = array[index2];
  return ret;
}
unittest {
  int[] array = [1, 2, 3, 4];
  int[] newArray = array.swap(1, 2);
  mixin(assertString("newArray == [1, 3, 2, 4]", "array"));
}

// 17a6edf7-f8a8-55f5-ae03-b8da7620e7a1
Maybe!ulong findIndex(T)(T[] array, T valueToFind) {
  import std.stdio : writeln;
  for(ulong i = 0; i < array.length; i++) {
    if(array[i] == valueToFind)
      return Maybe!ulong(i);
  }
  return Maybe!ulong.invalid;
}
unittest {
  int[] list = [0, 1, 2, 3, 4, 5];
  Maybe!ulong foundIndex = list.findIndex(2);
  mixin(assertString("foundIndex.valid", "foundIndex"));
  mixin(assertString("foundIndex == 2", "foundIndex"));
  foundIndex = list.findIndex(10);
  mixin(assertString("!foundIndex.valid", "foundIndex"));
}

// aa009fe4-2327-54ce-a8f8-075f3a45f623
ref T[] removeIndex(T)(ref T[] array, ulong indexToRemove) in {
  mixin(assertString!"Index out of bounds"("indexToRemove < array.length", "indexToRemove", "array.length"));
} do {
  for(ulong i = indexToRemove; i < array.length-1; i++)
    array[i] = array[i+1];
  array.length--;
  return array;
}
unittest {
  int[] list = [0, 1, 2, 3, 4, 5];
  list.removeIndex(3);
  mixin(assertString("list.length == 5", "list.length", "list"));
  mixin(assertString("list == [0, 1, 2, 4, 5]", "list.length", "list"));
}
unittest {
  int[] list = [0, 1];
  list.removeIndex(0);
  mixin(assertString("list.length == 1", "list.length", "list"));
  mixin(assertString("list == [1]", "list.length", "list"));
}
unittest {
  int[] list = [0];
  list.removeIndex(0);
  mixin(assertString("list.length == 0", "list.length", "list"));
  mixin(assertString("list == []", "list.length", "list"));
}

// 530ab49f-e5cf-5531-96e5-5f440a83a3ed
alias voidDelegate = void delegate();
void alternates(voidDelegate[] altList...) {
  foreach(voidDelegate alt; altList) {
    try {
      alt();
      return;
    } catch(Exception exc) {
      continue;
    }
  }
}
// 041116ff-ca09-5804-8414-76374782899f
unittest {
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
  mixin(assertString("whichSucceeded == 3", "whichSucceeded"));
}

// 2b19627e-0d25-53f6-bb9b-e9e2ff4d5d65
T appendToExceptions(T)(lazy T mightThrowException, string messageToAppend) {
  try {
    return mightThrowException();
  } catch(Exception oldException) {
    string newMsg = oldException.msg ~ "; " ~ messageToAppend;
    throw new Exception(newMsg, oldException.file, oldException.line);
  }
}
unittest {
  string excMsg = "";
  try {
    appendToExceptions(() {
      throw new Exception("xxx");
    }(), "yyy");
  } catch(Exception caughtExc) {
    excMsg = caughtExc.msg;
  }
  mixin(assertString(q"[excMsg == "xxx; yyy"]", "excMsg"));
}

T appendThisLineToExceptions(T, ulong line = __LINE__)(lazy T mightThrowException) {
  import std.conv : to;
  return appendToExceptions(mightThrowException(), "  (from line " ~ line.to!string ~ ")");
}

// 740ede60-885a-5305-ad7a-a3febf7c0bc2
string readEntireFile(from!"std.stdio".File file) {
  string retString;
  foreach(ubyte[] chunk; file.byChunk(1024))
    retString ~= cast(string)chunk;
  return retString;
}

string norEscapeQuotes(string stringToEscape) { // no-regex version of escapeQuotes
  import std.array : replace;
  return stringToEscape.replace("\"","\\\"");
}
string escapeQuotes(string stringToEscape) {
  import std.regex : ctRegex, replaceAll;
  static auto quoteRegex = ctRegex!"\"";
  return stringToEscape.replaceAll(quoteRegex, "\\$&");
}
unittest {
  string str = q"["asdf"]";
  string escStr = norEscapeQuotes(str);
  bool matches = (escStr == q"[\"asdf\"]");
  mixin(assertString("matches", "str", "escStr"));
}

enum string ctConcat(args...) = (){
  string ret;
  foreach(string str; args)
    ret ~= str;
  return ret;
}();

// ceea52dc-cd9d-5cd2-897f-3ae09a365923
enum string ctReplace(string original, string from, string to)  = (){
  import std.string : replace;
  return original.replace(from, to);
}();

unittest {
  string str = ctConcat!(
    "xxx",
    "yyy"
  );
  string correctOutput = "xxxyyy";
  mixin(assertString("str == correctOutput", "str", "correctOutput"));
}

// 98004b1f-1976-5b30-b673-86d0721e5a6b
template isVersion(string v) {
  static if(v == "debug") {
    debug
      enum bool isVersion = true;
    else
      enum bool isVersion = false;
  } else {
    mixin("version("~v~")
      enum bool isVersion = true;
    else
      enum bool isVersion = false;");
  }
}
// 10ee45c3-6643-5c18-9f98-fddb0c83328e
template isDebug(string v = "") {
  static if(v == "") {
    debug
      enum bool isDebug = true;
    else
      enum bool isDebug = false;
  } else {
    mixin("debug("~v~")
      enum bool isDebug = true;
    else
      enum bool isDebug = false;");
  }
}

// cddf19ef-2ec3-5af9-a552-a100c6123e52
bool isAlphanumWord(string str) {
  import std.regex: ctRegex, matchFirst;
  enum auto alphanumWordRegex = ctRegex!"^[a-z0-9A-Z]+$";
  auto captures = str.matchFirst(alphanumWordRegex);
  return !captures.empty;
}

unittest {
  mixin(assertString(q"[isAlphanumWord("ABC")]")); 
  mixin(assertString(q"[isAlphanumWord("abc")]")); 
  mixin(assertString(q"[isAlphanumWord("123")]")); 
  mixin(assertString(q"[!isAlphanumWord("with space")]")); 
  mixin(assertString(q"[!isAlphanumWord("with_underscore")]")); 
}

// 52eba935-9c14-50aa-8ad6-fedb99e7c46f
string escapeJsonHazardousCharacters(string stringToEscape) {
  import std.array : replace;
  import std.regex : ctRegex, replaceAll;
  static auto escapablesRegex = ctRegex!"[\\\\\"]";
  static auto newlineRegex = ctRegex!"\n";
  return stringToEscape.replaceAll(escapablesRegex, "\\$&").replaceAll(newlineRegex, "\\n");
}


// 69f21793-2f82-5a60-8832-88f4d37bfcaa
// Amount is equivalent to Enumerated!("none", "some", "most", "all", "over")
struct Amount { 
  private enum : ulong {none, some, most, all, over}
  private ulong value = none;
  alias value this;
  
  static Amount from(bool useExceptions = true)(string str) {
    Amount ret;
    switch(str) {
      case "none": ret.value = none;
      case "some": ret.value = some;
      case "most": ret.value = most;
      case "all":  ret.value = all;
      case "over": ret.value = over;
      default:
        static if(useExceptions)
          throw new Exception("No such Amount " ~ str);
        else
          assert(0);
    }
    return ret;
  }
}

// b3751d54-eca6-5351-8185-4a3d597e4fbc
struct Enumerated(enumMembers...) {
  alias This = typeof(this);
  
  mixin((){
    import std.conv : to;
    import std.uni : toLower;
    
    string ret = "enum : ulong {\n";
    
    static foreach(i, member; enumMembers) {
      ret ~= "  " ~ member;
      if(i < enumMembers.length - 1)
        ret ~= ",";
      ret ~=  " //\n";
    }
    ret ~= "}";
    return ret;
  }());
  /*
  ^ builds a mixin like:
  ```D
  enum : ulong {
    A,
    B,
    C
  }
  ```
  */
  
  ulong value;
  alias value this;
  
  static This from(bool useExceptions = true)(string str) {
    This ret;
    mixin((){
      return q"[
      switch(str) {
        ]" ~ (){
          string casesString;
          foreach(member; enumMembers)
            casesString ~= "    case \"" ~ member ~ "\": ret.value = " ~ member ~ "; break;\n";
          return casesString;
        }() ~ q"[
        default:
          static if(useExceptions)
            throw new Exception("No such Enumerated member " ~ str);
          else
            assert(0);
      }
      ]";
    }());
    /*
    ^ builds a mixin like:
    ```D
    switch(str) {
      case "A": ret.value = A; break;
      case "B": ret.value = B; break;
      case "C": ret.value = C; break;
      default:
        static if(useExceptions)
          throw new Exception("No such Enumerated member " ~ str);
        else
          assert(0);
    }
    ```
    */
    return ret;
  }
  
  bool hasValue(string str)() {
    return mixin("value == " ~ str);
  }
  bool atLeast(string str)() {
    return mixin("value >= " ~ str);
  }
}


// a5aea0f2-6481-545b-a747-843adb8103cf
void when()(lazy void noValue, bool condition) {
  if(condition)
    noValue();
}
T when(T)(lazy T value, bool condition, lazy T def) if(!is(T == void) && !is(T == noreturn)) {
  if(condition)
    return value();
  else
    return def();
}

unittest {
  assert(false).when(false);
  
  int x = 5;
  x += 1.when(false, -1);
  mixin(assertString("x == 4", "x"));
  
  void foo() {}
  
  foo().when(true);
  foo().when(false);
}

string[2] splitAtFirst(string splitterRegexString)(string stringToSplit) {
  import std.regex: ctRegex, Captures, matchFirst;
  
  enum auto splitterRegex = ctRegex!splitterRegexString;
  
  auto captures = stringToSplit.matchFirst(splitterRegex);
  
  if(captures.empty)
    return [stringToSplit, ""];
  
  return [captures.pre, captures.post];
}
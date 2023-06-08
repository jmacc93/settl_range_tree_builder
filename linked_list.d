

// 1c693d3c-e5d7-5ab4-85cf-201ceb18c30a
struct LinearIndex {
  ulong longForm;
  alias longForm this;
}

// 1c693d3c-e5d7-5ab4-85cf-201ceb18c30a
struct LListIndex {
  ulong longForm;
  alias longForm this;
}

// 49413a06-a121-531b-83e9-08fc16ddcfce
mixin template LListElementBody() {
  LListIndex prevIndex, nextIndex;
}

// 007dc309-4cfe-52d0-b612-17ed4b781764
mixin template LListBody(Element) {
  import lib : isNullInit, Stack;
  version(assert) import lib: assertString, writeStack;
  static assert(!isNullInit!Element); // no pointers allowed
  
  import std.traits : hasMember;
  static assert(hasMember!(Element, "prevIndex"));
  static assert(hasMember!(Element, "nextIndex"));
  
  alias This = typeof(this);
  
  // 92c9607c-b877-508e-aaf5-76aa64892297
  Stack!LListIndex availableIndices;
  Element[] elements;
  LListIndex firstIndex, lastIndex;
  ulong length = 0;
  
  this(T)(T[] elementArg) {
    foreach(T arg; elementArg)
      append(arg);
  }
  
  // 38a608e9-b0ae-5829-b39a-c1ddeb45954c
  bool empty() { return length == 0; }
  
  // 4563b7d7-7dc3-5263-8222-8b711037da18
  void increaseAvailableCapacity() {
    ulong oldLength = elements.length;
    if(elements.length == 0)
      elements.length = 10;
    else
      elements.length += elements.length / 2; // exponential growth base 1.5 -> 10, 15, 22, 34, 51, 76, 114, ...
    for(ulong i = elements.length-1; i > oldLength; i--)
      availableIndices ~= LListIndex(i);
    if(oldLength == 0)
      availableIndices ~= LListIndex(0);
  }
  
  // 22b7bc43-f49f-55c2-9662-8f543850d9fa
  LListIndex getAvailableIndex() {
    if(availableIndices.isEmpty())
      increaseAvailableCapacity();
    return availableIndices.pop();
  }
  
  LListIndex append(Element newElement) out { doPostModificationCheck(); } do {
    LListIndex newIndex = getAvailableIndex();
    newElement.prevIndex = lastIndex;
    elements[newIndex] = newElement;
    if(length != 0)
      elements[lastIndex].nextIndex = newIndex;
    else
      firstIndex = newIndex;
    lastIndex = newIndex;
    length++;
    return newIndex;
  }
  LListIndex prepend(Element newElement) out { doPostModificationCheck(); } do {
    LListIndex newIndex = getAvailableIndex();
    newElement.nextIndex = firstIndex;
    elements[newIndex] = newElement;
    if(length != 0)
      elements[firstIndex].prevIndex = newIndex;
    else
      lastIndex = newIndex;
    firstIndex = newIndex;
    length++;
    return newIndex;
  }
  
  // 3b085ebd-692c-5ddf-a6dd-71c0ca772ba0
  LListIndex append(ElemConstructorArgs...)(ElemConstructorArgs conArgs) out { doPostModificationCheck(); } do {
    return append(Element(conArgs));
  }
  LListIndex prepend(ElemConstructorArgs...)(ElemConstructorArgs conArgs) out { doPostModificationCheck(); } do {
    return prepend(Element(conArgs));
  }
  
  // 611191a7-c0b8-596f-b97d-9519166b5016
  ref This opBinary(string op : "~", T)(T elemValue) {
    return append(elemValue);
  }
  
  // 255ff887-04d9-5ef6-837c-4c64f99ba9aa
  ref This remove(LListIndex indexToRemove) in { checkIndex(indexToRemove); } out { doPostModificationCheck(); } do {
    availableIndices.push(indexToRemove);
    LListIndex prevIndex = elements[indexToRemove].prevIndex;
    LListIndex nextIndex = elements[indexToRemove].nextIndex;
    if(indexToRemove == lastIndex) {
      lastIndex = prevIndex;
    } else if(indexToRemove == firstIndex) {
      firstIndex = nextIndex;
    } else {
      elements[prevIndex].nextIndex = nextIndex;
      elements[nextIndex].prevIndex = prevIndex;
    }
    length--;
    return this;
  }
  ref This remove(LinearIndex linearIndexToRemove) in { checkIndex(linearIndexToRemove); } out {doPostModificationCheck();} do {
    LListIndex listIndexToRemove = nonlinearizeIndex(linearIndexToRemove);
    return remove(listIndexToRemove);
  } 
  
  // eeb59652-a849-5033-837a-0cdbef670b95
  LListIndex[] traversalOrder() const {
    LListIndex[] ret = [];
    foreach(LListIndex index; this)
      ret ~= index;
    return ret;
  }
  
  // f18ecd4e-277b-5f64-a9f0-533def16f1fc
  ref This swap(IndexA, IndexB)(IndexA indexAArg, IndexB indexBArg)  in {checkIndex(indexAArg);checkIndex(indexBArg);} out {doPostModificationCheck();} do {
    if(indexAArg == indexBArg)
      return this;
    
    LListIndex indexA = nonlinearizeIndex(indexAArg);
    LListIndex indexB = nonlinearizeIndex(indexBArg);
    
    version(assert) {
      LListIndex[] originalTravOrder = traversalOrder();
      LinearIndex linearA = linearizeIndex(indexA);
      LinearIndex linearB = linearizeIndex(indexB);
      
      import lib : libswap = swap;
      LListIndex[] predictedNewTravOrder = originalTravOrder.libswap(linearA, linearB); // lib.swap
    }
    
    LListIndex aOldPrevIndex = elements[indexA].prevIndex;
    LListIndex aOldNextIndex = elements[indexA].nextIndex;
    LListIndex bOldPrevIndex = elements[indexB].prevIndex;
    LListIndex bOldNextIndex = elements[indexB].nextIndex;
    
    elements[indexA].nextIndex = bOldNextIndex == indexA ? indexB : bOldNextIndex;
    elements[indexA].prevIndex = bOldPrevIndex == indexA ? indexB : bOldPrevIndex;
    elements[indexB].nextIndex = aOldNextIndex == indexB ? indexA : aOldNextIndex;
    elements[indexB].prevIndex = aOldPrevIndex == indexB ? indexA : aOldPrevIndex;
    
    bool aWasFirst = (indexA == firstIndex);
    bool aWasLast  = (indexA == lastIndex);
    bool bWasFirst = (indexB == firstIndex);
    bool bWasLast  = (indexB == lastIndex);
    
    if(aWasFirst)
      firstIndex = indexB;
    else if(aOldPrevIndex != indexB) // a has prev
      elements[aOldPrevIndex].nextIndex = indexB;
    
    if(aWasLast)
      lastIndex = indexB;
    else if(aOldNextIndex != indexB)// a has next
      elements[aOldNextIndex].prevIndex = indexB;
    
    if(bWasFirst)
      firstIndex = indexA;
    else if(bOldPrevIndex != indexA) // b has prev
      elements[bOldPrevIndex].nextIndex = indexA;
    
    if(bWasLast) 
      lastIndex = indexA;
    else if(bOldNextIndex != indexA)// b has prev
      elements[bOldNextIndex].prevIndex = indexA;

    
    version(assert) {
      LListIndex[] newTravOrder = traversalOrder();
      mixin(assertString!"Swapping changed size of traversal array"("originalTravOrder.length == newTravOrder.length", "originalTravOrder", "newTravOrder", "indexAArg", "indexBArg", "this.prettyString()", "this"));
      mixin(assertString!"Swapping produced wrong order"("newTravOrder == predictedNewTravOrder", "originalTravOrder", "newTravOrder", "predictedNewTravOrder", "indexAArg", "indexBArg", "this.prettyString()", "this"));
    }
    return this;
  }
  
  // 88add1a3-b3a2-596d-a862-76d6c1dc30b2
  ref Element opIndex(LListIndex index) in {checkIndex(index); } do {
    return get(index);
  }
  ref Element opIndex(LinearIndex index) in {checkIndex(index); } do {
    return get(index);
  }
  
  // f6610aa9-5333-5c9c-880c-54f9845e9e9b
  ref Element get(LListIndex index) in { checkIndex(index); } do {
    return elements[index];
  }
  ref Element get(LinearIndex lindex) in { checkIndex(lindex); } do {
    LListIndex listIndex = nonlinearizeIndex(lindex);
    return get(listIndex);
  }
  
  // 0e69355b-cb43-50c6-b8dc-1bc88d7b6f7e
  LListIndex nonlinearizeIndex(LinearIndex lindex) const in { checkIndex(lindex); } do {
    ulong i = 0;
    foreach(LListIndex index; this) {
      if(i == lindex)
        return index;
      i++;
    }
    version(assert) mixin(assertString!"Index not found"("false", "lindex", "length", "prettyString", "elements"));
  }
  LListIndex nonlinearizeIndex(LListIndex index) const in { checkIndex(index); } do { // identity
    return index;
  }
  
  // a3eecca7-7d5a-5a04-8923-4127f833463c
  LinearIndex linearizeIndex(LinearIndex lindex) const in { checkIndex(lindex); } do { // identity
    return lindex;
  }
  LinearIndex linearizeIndex(LListIndex index) const in { checkIndex(index); } do {
    ulong i = 0;
    foreach(LListIndex loopIndex; this) {
      if(loopIndex == index)
        return LinearIndex(i);
      i++;
    }
    version(assert) mixin(assertString!"Index not found"("false", "index", "length", "prettyString", "elements"));
  }
  
  // 1c081a8e-1f34-536c-915e-f89137ab7387
  bool isIndexValid(LListIndex index) const {
    foreach(LListIndex scanIndex; this) {
      if(scanIndex == index)
        return true;
    }
    return false;
  }
  
  // 183ed6b2-76c4-5e0b-ab43-697d64a7d75b
  version(assert) {
    private void checkIndex(LinearIndex index) const {
      mixin(assertString!"LinearIndex outside list"("index < length", "index", "length", "this.prettyString()"));
    }
    private void checkIndex(LListIndex index) const {
      mixin(assertString!"No such index found"("isIndexValid(index)", "index", "elements.length", "this.prettyString"));
    }
    
    private void checkFirstLastIndices() const {
      if(length == 0)
        return;
        
      mixin(assertString!"first index outside list"("firstIndex < elements.length", "firstIndex", "elements.length", "lastIndex", "availableIndices", "this"));
      mixin(assertString!"last index outside list"( "lastIndex  < elements.length", "firstIndex", "elements.length", "lastIndex", "availableIndices", "this"));
    }
    private void checkFirstLastLinearIndices() const {
      if(length == 0)
        return;
      
      LListIndex firstListIndex = nonlinearizeIndex(LinearIndex(0));
      mixin(assertString!"nonlinearizeIndex bad first index"("firstListIndex == firstIndex", "firstListIndex", "firstIndex", "lastIndex", "length", "this", "this.prettyString()"));
      if(length > 1) {
        LListIndex secondListIndex = nonlinearizeIndex(LinearIndex(1));
        LListIndex realListIndex   = elements[firstIndex].nextIndex;
        mixin(assertString!"nonlinearizeIndex bad second"("secondListIndex == realListIndex", "secondListIndex", "realListIndex", "length", "this", "this.prettyString()"));
      }
      LListIndex lastListIndex = nonlinearizeIndex(LinearIndex(length-1));
      mixin(assertString!"nonlinearizeIndex bad first index"("lastListIndex == lastIndex", "lastListIndex", "lastIndex", "firstIndex", "length", "this", "this.prettyString()"));
    }
    private void checkPrevNextSymmetry() const {
      // check elements' next, prev index symmetry
      foreach(LListIndex elemIndex, const(Element) elem; this) {
        if(elemIndex != firstIndex) {
          const(Element) prevElem = elements[elem.prevIndex];
          mixin(assertString!"Element X's prev element's next isn't X"("elemIndex == prevElem.nextIndex", "elemIndex", "elem.prevIndex", "prevElem", "prevElem.nextIndex", "elements.length", "firstIndex", "lastIndex", "availableIndices", "length", "this"));
        }
        
        if(elemIndex != lastIndex) {
          const(Element) nextElem = elements[elem.nextIndex];
          mixin(assertString!"Element X's next element's prev isn't X"("elemIndex == nextElem.prevIndex", "elemIndex", "elem.nextIndex", "nextElem", "nextElem.prevIndex", "elements.length", "firstIndex", "lastIndex", "availableIndices", "length", "this"));
        }
      }
    }
    private void checkLengthMatches() const {
      // check length property is accurate
      ulong calculatedLength = 0;
      foreach(LListIndex elemIndex; this)
        calculatedLength++;
      // check length property is accurate
      mixin(assertString!"Length property doesn't match true length"("length == calculatedLength", "length", "calculatedLength", "firstIndex", "lastIndex", "availableIndices", "length", "this"));
    }
    private void checkAvailableIndicesArentInTraversal() const {
      import lib : intersect;
      LListIndex[] traversal = traversalOrder();
      LListIndex[] traversalIntersection = availableIndices.intersect(traversal);
      mixin(assertString!"Elements in use are also in availableIndices!"("traversalIntersection.length == 0", "traversalIntersection"));
    }
    private void checkIntermediateElementsDontPointToSelf() const {
      LinearIndex linearizeIndex = LinearIndex(0);
      foreach(LListIndex currentIndex; this) {
        const(Element) element = elements[currentIndex];
        if(currentIndex != lastIndex)
          mixin(assertString!"Element next points to itself"("element.nextIndex != currentIndex", "element", "linearizeIndex", "currentIndex", "length"));
        if(currentIndex != firstIndex)
          mixin(assertString!"Element prev points to itself"("element.prevIndex != currentIndex", "element", "linearizeIndex", "currentIndex", "length"));
        linearizeIndex++;
      }
    }
    void checkAvailableIndicesAreInsideElementsArray() const { // check available indices are inside elements array
      foreach(ulong indexInStack, LListIndex availIndex; availableIndices) {
        mixin(assertString!"Available index stack has element outside list"("availIndex < elements.length || availIndex == 0", "indexInStack", "availIndex", "elements.length", "firstIndex", "lastIndex", "availableIndices", "length", "this"));
      }
    }
    private void doPostModificationCheck() const {
      checkFirstLastLinearIndices();
      checkPrevNextSymmetry();
      checkIntermediateElementsDontPointToSelf();
      checkLengthMatches();
      checkAvailableIndicesArentInTraversal();
      checkAvailableIndicesAreInsideElementsArray();
    }
  }
  
  // 989b080c-4e83-5f8b-ac03-ac2d9a2b2ac8
  bool opEquals(T)(T[] array) {
    if(array.length != this.length)
      return false;
    ulong arrayIndex = 0;
    foreach(LListIndex index; this) {
      Element element = elements[index];
      if(array[arrayIndex++] != element)
        return false;
    }
    return true;
  }
  
  // b0bf0f82-50cc-5943-b29b-e24277cfd4a8
  T[] asArray(T)() {
    T[] ret;
    foreach(LListIndex index; this) {
      Element element = elements[index];
      ret ~= cast(T)element;
    }
    return ret;
  }
  
  // 632ae617-8fab-599b-aff8-00f0aebdad65
  string prettyString() const {
    import std.conv : to;
    string ret = "[\n";
    ret ~= "  first: ";  ret ~= firstIndex.to!string; ret ~= "\n";
    ret ~= "  last: ";   ret ~= lastIndex.to!string;  ret ~= "\n";
    ret ~= "  length: "; ret ~= length.to!string;     ret ~= "\n";
    ret ~= "  [\n";
    foreach(LListIndex index; this) {
      const(Element) elem = elements[index];
      ret ~= "    "; ret ~= index.to!string;
      ret ~= ": <- "; ret ~= elem.prevIndex.to!string;
      ret ~= " ";  ret ~= elem.nextIndex.to!string; ret ~= " ->";
      ret ~= " full: "; ret ~= elem.to!string; ret ~= "\n";
    }
    ret ~= "  ]\n";
    return ret;
  }

  // f60d571f-4ae5-57f8-8125-e7fb4cfe4ad1
  int opApply(scope int delegate(LListIndex, const(Element)) dg) const {
    if(length == 0)
      return 1;
    LListIndex currentIndex = firstIndex;
    version(assert) {
      bool[LListIndex] visited;
      LListIndex[] previouslyTraversed = [];
    }
    while(true) {
      version(assert) {
        mixin(assertString!"Cycle detected"("!visited.get(currentIndex, false)", "visited", "elements[currentIndex]", "currentIndex", "previouslyTraversed", "this"));
        visited[currentIndex] = true;
        previouslyTraversed ~= currentIndex;
      }
      int result = dg(currentIndex, elements[currentIndex]);
      if(result > 0)
        return result;
      
      if(currentIndex == lastIndex)
        return 1;
      currentIndex = elements[currentIndex].nextIndex;
    }
  }
  int opApply(scope int delegate(LListIndex) dg) const {
    if(length == 0)
      return 1;
    LListIndex currentIndex = firstIndex;
    version(assert) {
      bool[LListIndex] visited;
      LListIndex[] previouslyTraversed = [];
    }
    while(true) {
      version(assert) {
        mixin(assertString!"Cycle detected"("!visited.get(currentIndex, false)", "visited", "elements[currentIndex]", "currentIndex", "previouslyTraversed", "this"));
        visited[currentIndex] = true;
        previouslyTraversed ~= currentIndex;
      }
      int result = dg(currentIndex);
      if(result > 0)
        return result;
      
      if(currentIndex == lastIndex)
        return 1;
      currentIndex = elements[currentIndex].nextIndex;
    }
  }
  
}


// ===== Unit tests =====

// bdaf793a-bd1f-58ff-a858-b6e228e7c55a
struct LListElement(T) {
  mixin LListElementBody!();
  T value;
  
  this(T value_) {
    value = value_;
  }
  
  bool opEquals(T other) { return value == other; }
  T opCast(Type : T)() { return value; }
}

version(unittest) {
  import lib: assertString, writeStack;
}

struct LList(T) {
  mixin LListBody!(LListElement!T);
}
unittest { // zero and one element
  auto list = LList!int();
  mixin(assertString("list.length == 0", "list", "list.asArray!int", "list.prettyString"));
  list.append(5);
  mixin(assertString("list.length == 1", "list", "list.asArray!int", "list.prettyString"));
  mixin(assertString("list == [5]", "list", "list.asArray!int", "list.prettyString"));
  list.remove(LinearIndex(0));
  mixin(assertString("list.length == 0", "list", "list.asArray!int", "list.prettyString"));
  mixin(assertString("list == cast(int[])[]", "list", "list.asArray!int", "list.prettyString"));
}
unittest { // zero and one element
  auto list = LList!int();
  for(int i = 0; i < 100; i++)
    list.append(i);
  mixin(assertString("list.length == 100", "list.length", "list", "list.asArray!int", "list.prettyString"));
  while(list.length > 0)
    list.remove(LinearIndex(list.length - 1));
  mixin(assertString("list.length == 0", "list.length", "list", "list.asArray!int", "list.prettyString"));
  mixin(assertString("list == cast(int[])[]", "list.length", "list", "list.asArray!int", "list.prettyString"));
  for(int i = 0; i < 100; i++)
    list.append(i);
  mixin(assertString("list.length == 100", "list.length", "list", "list.asArray!int", "list.prettyString"));
}
unittest { // small append, prepending, equality
  auto list = LList!int([3, 5]);
  mixin(assertString("list[list.firstIndex] == 3", "list", "list.asArray!int"));
  mixin(assertString("list.length == 2", "list", "list.asArray!int"));
  mixin(assertString("list[list.lastIndex] == 5", "list", "list.asArray!int"));
  // append
  list.append(7);
  mixin(assertString("list.length == 3", "list", "list.asArray!int"));
  mixin(assertString("list[list.lastIndex] == 7", "list", "list.asArray!int"));
  mixin(assertString("list == [3, 5, 7]", "list", "list.asArray!int"));
  // prepend
  list.prepend(2);
  mixin(assertString("list.length == 4", "list", "list.asArray!int"));
  mixin(assertString("list == [2, 3, 5, 7]", "list", "list.asArray!int"));
  // remove
  LListIndex indexToRemove = list.nonlinearizeIndex(LinearIndex(2));
  list.remove(indexToRemove);
  mixin(assertString("list == [2, 3, 7]", "list", "list.asArray!int"));
  
  import std.stdio:writeln;
  list.swap(LinearIndex(0), LinearIndex(list.length-1));
  mixin(assertString("list == [7, 3, 2]", "list", "list.asArray!int"));
  mixin(assertString("list[list.firstIndex] == 7", "list", "list.asArray!int"));
  mixin(assertString("list[list.lastIndex] == 2", "list", "list.asArray!int"));
  
  list.append(13);
  mixin(assertString("list == [7, 3, 2, 13]", "list", "list.asArray!int"));
  list.swap(list.elements[list.firstIndex].nextIndex, list.elements[list.lastIndex].prevIndex);
  mixin(assertString("list == [7, 2, 3, 13]", "list", "list.asArray!int"));
}
unittest { // append, prepending, equality
  auto list = LList!int([3, 5, 7, 11, 13, 17]);
  mixin(assertString("list[list.firstIndex] == 3", "list", "list.asArray!int"));
  mixin(assertString("list[list.lastIndex] == 17", "list", "list.asArray!int"));
  // append
  list.append(23);
  mixin(assertString("list[list.lastIndex] == 23", "list", "list.asArray!int"));
  mixin(assertString("list == [3, 5, 7, 11, 13, 17, 23]", "list", "list.asArray!int"));
  // prepend
  list.prepend(2);
  mixin(assertString("list == [2, 3, 5, 7, 11, 13, 17, 23]", "list", "list.asArray!int"));
  // remove
  LListIndex indexToRemove = list.nonlinearizeIndex(LinearIndex(4));
  list.remove(indexToRemove);
  mixin(assertString("list == [2, 3, 5, 7, 13, 17, 23]", "list", "list.asArray!int"));
}
unittest { // check foreach body on empty list is never called
  auto list = LList!int();
  bool called = false;
  foreach(LListIndex index; list)
    called = true;
  mixin(assertString("!called", "list", "list.asArray!int"));
  called = false;
  foreach(LListIndex index; list)
    called = true;
  mixin(assertString("!called", "list", "list.asArray!int"));
}

debug import lib: dbgwritelnMixin;
import lib: hasModule, isVersion;

// cabbb068-bbcc-5c01-b115-35aba6f7ee07

// 91cfb2a7-ddb3-51bd-855f-0f2925150c79
struct TreeIndex {
  import linked_list: LListIndex;
  LListIndex listIndexForm;
  alias listIndexForm this;
  
  this(ulong ulongForm) { listIndexForm = LListIndex(ulongForm); }
}

// c403ebf7-e576-5736-b882-062fc6e76bda
mixin template NodeBody() {
  import linked_list: LListIndex, LListElementBody;
  import lib: Maybe;
  mixin LListElementBody!(); // prevIndex, nextIndex properties
  // alias asLListElement this;
  
  TreeIndex[] childIndices;
  TreeIndex   parentIndex;
  
  bool isTerminal() { return childIndices.length == 0; }
}

// 963bcc1c-243f-586e-9417-b5ad5be412f3
mixin template TreeBody(Node) {
  import lib: Stack, findIndex, removeIndex, iff, Maybe;
  import linked_list: LinearIndex, LListIndex;
  
  // 6a1e1281-8074-5c24-9dc7-e8e5bd3f78ff
  static assert(!isNullInit!Node); // Node must be a struct
  
  import linked_list : LListIndex;
  import std.traits : hasMember;
  static assert(hasMember!(Node, "prevIndex"));
  static assert(hasMember!(Node, "nextIndex"));
  static assert(hasMember!(Node, "childIndices"));
  static assert(hasMember!(Node, "parentIndex"));
  static assert(hasMember!(Node, "isTerminal"));
  
  alias This = typeof(this);
  
  // cb67b8fd-da14-558e-8149-25a021126c69
  import linked_list : LListBody;
  mixin LListBody!Node asLList; // makes TreeBody also into a linked list body
  alias asLList this;
  // Note: TreeBody has all the properties and methods from LListBody, look at LListBody for apparently missing properties / methods
  
  // a25bc4c5-984f-5b95-90e8-33595ad6a6bf
  TreeIndex rootIndex;
  bool hasRoot = false; // equivalent to (length != 0) ie (!empty)
  
  // 8f733938-9409-5eee-849c-b6f8bf8d5e46
  string indentedLinesString() {
    string ret = "";
    applyFirstChildrenFirst(rootIndex, (TreeIndex index){
      import std.stdio : writeln;
      import std.array : replicate;
      
      ulong depth = findDepth(index);
      
      writeln(replicate("  ", depth), get(index));
    });
    return ret;
  }
  
  static if(hasModule!"std.json" && !isVersion!"noJson") {
    import std.json : JSONValue;
    
    // 577c198a-b112-5262-8881-795164732f24
    JSONValue toJson() {
      return toJson(rootIndex);
    }
    JSONValue toJson(TreeIndex from) {
      JSONValue furledJsonValue = furlBranch(from, (JSONValue[] childJsonValues, TreeIndex nodeIndex) {
        JSONValue childrenJson;
        if(childJsonValues.length == 0)
          childrenJson.array = new JSONValue[](0);
        else
          childrenJson.array = childJsonValues;
          
        Node* node = &get(nodeIndex);
        
        static if(__traits(compiles, node.toJson())) {
          JSONValue nodeValue = node.toJson();
          return JSONValue([
            "children": childrenJson,
            "nodeValue": nodeValue
          ]);
        } else {
          return JSONValue([
            "children": childrenJson
          ]);
        }
      });
      return furledJsonValue;
    }
    
  }
  
  // 9e56d0e8-fedb-52e6-a04f-b81b1cf2a9e3
  this(NodeConstructorArgs...)(NodeConstructorArgs conargs) {
    addRoot(conargs);
  }
  
  // e231b97e-a1ec-5c80-ae8c-4054d310fe1b
  ref Node get(TreeIndex treeIndex) in {asLList.checkIndex(treeIndex.listIndexForm);} do {
    return asLList.get(treeIndex.listIndexForm);
  }
  
  // d60d71bd-5dd6-5fc4-813a-25170e3520db
  TreeIndex addRoot(NodeConstructorArgs...)(NodeConstructorArgs conargs) out {doPostModificationCheck(); } do {
    mixin(assertString!"Root exists!"("length == 0", "asLList.length", "rootIndex", "this"));
    auto newNode = Node(conargs);
    LListIndex newRootListIndex = asLList.append(newNode);
    hasRoot = true;
    TreeIndex newRootIndex = TreeIndex(newRootListIndex);
    rootIndex = newRootIndex;
    return newRootIndex;
  }
  
  // 50b35196-0fd3-56ab-8fdd-cbb1dfad36ee
  TreeIndex appendChild(NodeConstructorArgs...)(TreeIndex parentIndex, NodeConstructorArgs conargs)  in {asLList.checkIndex(parentIndex.listIndexForm);} out {doPostModificationCheck(); } do {
    auto newNode = Node(conargs);
    newNode.parentIndex = parentIndex;
    LListIndex newChildListIndex = asLList.append(newNode);
    Node* parentNode = &get(parentIndex);
    TreeIndex newChildIndex = TreeIndex(newChildListIndex);
    parentNode.childIndices ~= newChildIndex;
    return newChildIndex;
  }
  TreeIndex prependChild(NodeConstructorArgs...)(TreeIndex parentIndex, NodeConstructorArgs conargs)  in {asLList.checkIndex(parentIndex.listIndexForm);} out {doPostModificationCheck(); } do {
    auto newNode = Node(conargs);
    newNode.parentIndex = parentIndex;
    LListIndex newChildListIndex = asLList.append(newNode);
    Node* parentNode = &get(parentIndex);
    TreeIndex newChildIndex = TreeIndex(newChildListIndex);
    parentNode.childIndices = newChildIndex ~ parentNode.childIndices;
    return newChildIndex;
  }
  
  // d69417f9-54cc-5bb8-9050-b494ae6f505d
  TreeIndex parentIndex(TreeIndex nodeIndex) const {
    const(Node) node = asLList.elements[nodeIndex.listIndexForm];
    return node.parentIndex;
  }
  // d2ada34e-3a4d-5c16-8f64-e7a23906264f
  TreeIndex childIndex(TreeIndex parentIndex, ulong childArrayIndex) const in {
    const(Node) parentNode = asLList.elements[parentIndex.listIndexForm];
    mixin(assertString("childArrayIndex < parentNode.childIndices.length", "childArrayIndex", "parentNode.childIndices.length", "this"));
  } do {
    const(Node) parentNode = asLList.elements[parentIndex.listIndexForm];
    return parentNode.childIndices[childArrayIndex];
  }
  
  // 11288391-89be-5326-969a-701b5d7796ea
  ref This disconnectChild(TreeIndex parentTreeIndex, ulong childArrayIndex) in {
    asLList.checkIndex(parentTreeIndex.listIndexForm);
    Node* parentNode = &get(parentTreeIndex);
    mixin(assertString("childArrayIndex < parentNode.childIndices.length", "childArrayIndex", "parentNode.childIndices", "parentNode"));
  } do {
    Node* parentNode = &get(parentTreeIndex);
    parentNode.childIndices.removeIndex(childArrayIndex);
    return this;
  }
  
  // f2aa63e4-b12b-5d48-9068-f6588636b58f
  ref This disconnectChild(TreeIndex parentTreeIndex, TreeIndex childTreeIndex) in {
    asLList.checkIndex(parentTreeIndex.listIndexForm);
    asLList.checkIndex(childTreeIndex.listIndexForm);
    Node* parentNode = &get(parentTreeIndex);
    Node* childNode  = &get(childTreeIndex);
    mixin(assertString("childNode.parentIndex == parentTreeIndex", "parentTreeIndex", "childNode", "parentNode"));
    Maybe!ulong childArrayIndexInParent = parentNode.childIndices.findIndex(childTreeIndex);
    mixin(assertString!"Node not found as child of in parent"("childArrayIndexInParent.valid", "childArrayIndexInParent", "parentTreeIndex", "childTreeIndex", "parentNode.childIndices", "parentNode"));
  } do {
    Node* parentNode = &get(parentTreeIndex);
    Maybe!ulong maybeChildArrayIndexToRemove = parentNode.childIndices.findIndex(childTreeIndex);
    parentNode.childIndices.removeIndex(maybeChildArrayIndexToRemove.value);// assuming did find index
    return this;
  }
  
  // 899c5147-5448-526b-b696-5f0714466af5
  ref This remove(TreeIndex indexToRemove) in {asLList.checkIndex(indexToRemove.listIndexForm); } out {doPostModificationCheck(); } do {
    
    // remove everything?
    if(indexToRemove == rootIndex) {
      applyDeepestChildrenFirst(rootIndex, (TreeIndex childIndex) {
        asLList.remove(childIndex.listIndexForm);
      });
      hasRoot = false;
      return this;
    }
    
    // else, disconnect the node's parent and remove the nodes subtree
    Node* nodeToRemove = &get(indexToRemove);
    disconnectChild(nodeToRemove.parentIndex, indexToRemove);
    applyDeepestChildrenFirst(indexToRemove, (TreeIndex childIndex) {
      asLList.remove(childIndex.listIndexForm);
    });
    return this;
  }
  
  // 86a3785e-758d-506c-9572-7b1d4c5cf9ff
  ulong findDepth(TreeIndex index) const in { asLList.checkIndex(index.listIndexForm); } do {
    TreeIndex currentIndex = index;
    ulong retDepth = 0;
    while(currentIndex != rootIndex) {
      retDepth++;
      currentIndex = asLList.elements[currentIndex.listIndexForm].parentIndex;
    }
    return retDepth;
  }
  
  // 0ee74879-1218-5a31-aba4-94f5e34412bd
  // modification checks:
  version(assert) {
    void checkHasRoot() const { // hasRoot <=> (length != 0)
      mixin(assertString!"hasRoot doesn't agree with length"("iff(hasRoot, length != 0)", "hasRoot", "length", "this"));
    }
    void checkRootIndex() const {
      if(hasRoot) {
        mixin(assertString!"Root index isn't within node list"("rootIndex < length", "rootIndex", "length", "this"));
      }
    }
    void checkNoChildIndexDuplicates() const {
      LListIndex nodeListIndex = asLList.firstIndex;
      nodeListIndex = asLList.firstIndex;
      while(nodeListIndex != asLList.lastIndex) {
        const(Node) node = asLList.elements[nodeListIndex];
        foreach(TreeIndex childIndex; node.childIndices) {
          import std.algorithm : count;
          ulong childIndexCount = node.childIndices.count(childIndex);
          mixin(assertString("childIndexCount == 1", "node.childIndices", "childIndexCount", "node", "this"));
        }
        nodeListIndex = node.nextIndex;
      }
    }
    void checkChildParentSymmetry() const {
      if(length == 0)
        return;
      
      // check node X's children have X as parent
      // Each node as a parent node
      LListIndex nodeListIndex = asLList.firstIndex;
      while(nodeListIndex != asLList.lastIndex) {
        const(Node) node = asLList.elements[nodeListIndex];
        // Each of that parent's children
        for(ulong i = 0; i < node.childIndices.length; i++) {
          TreeIndex childIndex = node.childIndices[i];
        // foreach(TreeIndex childIndex; node.childIndices) {
          // check the parent node is the child's parent
          const(Node) childNode = asLList.elements[childIndex.listIndexForm];
          mixin(assertString!"Node parent mismatch"("childNode.parentIndex == nodeListIndex", "childNode.parentIndex", "nodeListIndex", "childIndex", "node", "this"));
        }
        nodeListIndex = node.nextIndex;
      }
      
      // check node X's parent has X as child
      // Each node as a child node
      nodeListIndex = asLList.firstIndex;
      while(nodeListIndex != asLList.lastIndex) {
        const(Node) node = asLList.elements[nodeListIndex];
        alias childNode = node;
        if(nodeListIndex == rootIndex) {
          nodeListIndex = childNode.nextIndex;
          continue; // root node has no parent
        }
        const(Node) parentNode = asLList.elements[childNode.parentIndex];
        Maybe!ulong maybeFoundIndex = parentNode.childIndices.findIndex(TreeIndex(nodeListIndex));
        bool didFind = maybeFoundIndex.valid;
        mixin(assertString!"Node parent mismatch"("didFind", "parentNode.childIndices", "parentNode", "nodeListIndex", "this"));
        nodeListIndex = childNode.nextIndex;
      }
    }
    void checkForCycles() const {
      // check each child is seen by only one parent
      bool[LListIndex] seenAsChild = [rootIndex: true];
      LListIndex nodeIndex = asLList.firstIndex;
      while(nodeIndex != asLList.lastIndex) {        
        foreach(TreeIndex childIndex; this.elements[nodeIndex].childIndices) {
          bool alreadySeenAsChild = seenAsChild.get(childIndex, false);
          mixin(assertString("!alreadySeenAsChild", "nodeIndex", "this.elements[nodeIndex]", "childIndex", "this.elements[childIndex]", "this"));
          seenAsChild[childIndex] = true;
        }
        nodeIndex = this.elements[nodeIndex].nextIndex;
      }
    }
    void doPostModificationCheck() {
      checkHasRoot();
      checkRootIndex();
      checkNoChildIndexDuplicates();
      checkChildParentSymmetry();
      checkForCycles();
    }
  }
  
  // b2ccdc0e-0e51-57d4-a065-ea75639efcdf
  ref This applyDeepestChildrenFirst(TreeIndex from, void delegate(TreeIndex) bodyDg) in {asLList.checkIndex(from.listIndexForm);} do {
    struct State { TreeIndex nodeTreeIndex; ulong nextChildArrayIndex; }
    Stack!State stateStack;
    stateStack.push(State(from, 0));
    while(true) {
      State loopState  = stateStack.pop();
      TreeIndex nodeIndex = loopState.nodeTreeIndex;
      Node* node = &get(nodeIndex);
      ulong nextChildIndex = loopState.nextChildArrayIndex;
      if(nextChildIndex >= node.childIndices.length) { // done with children, call loop body on this then up to parent
        bodyDg(nodeIndex);
      } else { // not done with all children, continue iterating over children
        stateStack.push(State(nodeIndex, nextChildIndex + 1));
        stateStack.push(State(node.childIndices[nextChildIndex]));
      }
      if(stateStack.isEmpty)
        break;
    }
    return this;
  }
  
  // 45a392c1-1f55-5707-8743-3a0ba2d78cb6
  ref This applyShallowestNodesFirst(TreeIndex from, void delegate(TreeIndex) bodyDg) in {asLList.checkIndex(from.listIndexForm); } do {
    TreeIndex[] currentDepthList = [from];
    
    while(currentDepthList.length > 0) {
      TreeIndex[] nextDepthList = [];
      foreach(TreeIndex index; currentDepthList) {
        bodyDg(index);
        foreach(TreeIndex childIndex; get(index).childIndices)
          nextDepthList ~= childIndex;
      }
      currentDepthList = nextDepthList;
    }
    return this;
  }
  
  // 083b2dd5-79a9-5d3e-a70e-dca9d201797e
  ref This applyFirstChildrenFirst(TreeIndex from, void delegate(TreeIndex) bodyDg) in {asLList.checkIndex(from.listIndexForm); } do {
    Stack!TreeIndex applyStack;
    applyStack.push(from);
    while(!applyStack.isEmpty) {
      TreeIndex currentIndex = applyStack.pop();
      bodyDg(currentIndex);
      foreach_reverse(TreeIndex childIndex; get(currentIndex).childIndices)
        applyStack.push(childIndex);
    }
    return this;
  }
  
  // Note: this uses recursion
  T furlBranch(T)(TreeIndex from, T delegate(T[], TreeIndex) bodyDg) const in {asLList.checkIndex(from.listIndexForm); } do {
    T[] intermediateValues;
    foreach(TreeIndex childIndex; asLList.elements[from.listIndexForm].childIndices) {
      T furledChildSubtreeValue = furlBranch(childIndex, bodyDg);
      intermediateValues ~= furledChildSubtreeValue;
    }
    return bodyDg(intermediateValues, from);
  }
  
  // ed2a9fa3-c95d-5938-bf70-f16e894c4b64
  // loop generator
  int delegate(int delegate(TreeIndex)) depthFirst(TreeIndex from) in {asLList.checkIndex(from.listIndexForm);} do {
    return (int delegate(TreeIndex) bodyDg) {
      applyDeepestChildrenFirst(from, (TreeIndex index) {
        bodyDg(index);
      });
      return 0;
    };
  }
}

// 25e8f47d-8dba-5c73-b974-78d426726e43

version(unittest) {
  import lib: assertString, writeStack;
  struct IntNode { mixin NodeBody!(); uint value; this(uint value_) { value = value_; }}
  struct IntTree {  mixin TreeBody!IntNode; }
}

unittest { // adding nodes deeply, depthFirst generator, removing node branch
  auto tree = IntTree();
  TreeIndex root = tree.addRoot(1000);
  TreeIndex r1 = tree.appendChild(tree.rootIndex, 1010);
  TreeIndex r2 = tree.appendChild(tree.rootIndex, 1020);
  mixin(assertString("tree.get(root).childIndices.length == 2", "tree.get(root)", "tree.get(root).childIndices", "tree.length", "tree"));
  TreeIndex r11 = tree.appendChild(r1, 1011);
  TreeIndex r12 = tree.appendChild(r1, 1012);
  TreeIndex r21 = tree.appendChild(r2, 1021);
  TreeIndex r22 = tree.appendChild(r2, 1022);
  mixin(assertString!"Wrong node count"("tree.length == 7", "tree.length", "tree"));
  
  // applyDeepestChildrenFirst deep order
  int[] travValues = [];
  tree.applyDeepestChildrenFirst(root, (TreeIndex nodeIndex) {
    IntNode node = tree.get(nodeIndex);
    travValues ~= node.value;
  });
  mixin(assertString("travValues == [1011, 1012, 1010, 1021, 1022, 1020, 1000]", "travValues", "tree"));
  
  // applyDeepestChildrenFirst depths
  ulong[] depths = [];
  tree.applyDeepestChildrenFirst(root, (TreeIndex nodeIndex) {
    depths ~= tree.findDepth(nodeIndex);
  });
  mixin(assertString("depths == [2, 2, 1, 2, 2, 1, 0]", "depths", "tree"));
  
  // applyFirstChildrenFirst descending order
  travValues = [];
  tree.applyFirstChildrenFirst(root, (TreeIndex nodeIndex) {
    IntNode node = tree.get(nodeIndex);
    travValues ~= node.value;
  });
  mixin(assertString("travValues == [1000, 1010, 1011, 1012, 1020, 1021, 1022]", "travValues", "tree"));
  
  // applyFirstChildrenFirst depths
  depths = [];
  tree.applyFirstChildrenFirst(root, (TreeIndex nodeIndex) {
    depths ~= tree.findDepth(nodeIndex);
  });
  mixin(assertString("depths == [0, 1, 2, 2, 1, 2, 2]", "depths", "tree"));
  
  // applyShallowestNodesFirst shallow order
  travValues = [];
  tree.applyShallowestNodesFirst(root, (TreeIndex nodeIndex) {
    IntNode node = tree.get(nodeIndex);
    travValues ~= node.value;
  });
  mixin(assertString("travValues == [1000, 1010, 1020, 1011, 1012, 1021, 1022]", "travValues", "tree"));
  
  // applyShallowestNodesFirst depths
  depths = [];
  tree.applyShallowestNodesFirst(root, (TreeIndex nodeIndex) {
    depths ~= tree.findDepth(nodeIndex);
  });
  mixin(assertString("depths == [0, 1, 1, 2, 2, 2, 2]", "depths", "tree"));
  
  // applyDeepestChildrenFirst subtree order
  travValues = [];
  tree.applyDeepestChildrenFirst(r1, (TreeIndex nodeIndex) {
    IntNode node = tree.get(nodeIndex);
    travValues ~= node.value;
  });
  mixin(assertString("travValues == [1011, 1012, 1010]", "travValues", "tree"));
  
  // remove node
  tree.remove(r1);
  mixin(assertString("tree.length == 4", "tree.length", "tree"));
  travValues = [];
  tree.applyDeepestChildrenFirst(root, (TreeIndex nodeIndex) {
    IntNode node = tree.get(nodeIndex);
    travValues ~= node.value;
  });
  mixin(assertString("travValues == [1021, 1022, 1020, 1000]", "travValues", "tree"));
  
  // remove root
  tree.remove(tree.rootIndex);
  mixin(assertString("tree.length == 0", "tree.length", "tree"));  
}

unittest { // prepend test
  auto tree = IntTree();
  TreeIndex root = tree.addRoot(1000);
  tree.appendChild(tree.rootIndex, 1010);
  tree.appendChild(tree.rootIndex, 1020);
  tree.prependChild(tree.rootIndex, 1030);
  tree.prependChild(tree.rootIndex, 1040);
  mixin(assertString("tree.get(root).childIndices.length == 4", "tree.length", "tree.get(root)", "tree"));  
  int[] travValues = [];
  tree.applyDeepestChildrenFirst(root, (TreeIndex nodeIndex) {
    IntNode node = tree.get(nodeIndex);
    travValues ~= node.value;
  });
  mixin(assertString("travValues == [1040, 1030, 1010, 1020, 1000]", "travValues", "tree.get(root)", "tree"));
}

unittest { // parentIndex, getChildIndex
  auto tree = IntTree();
  TreeIndex root = tree.addRoot(1000);
  TreeIndex r1 = tree.appendChild(tree.rootIndex, 1010);
  TreeIndex r2 = tree.appendChild(tree.rootIndex, 1020);
  TreeIndex r11 = tree.appendChild(r1, 1011);
  TreeIndex r12 = tree.appendChild(r1, 1012);
  TreeIndex r21 = tree.appendChild(r2, 1021);
  TreeIndex r22 = tree.appendChild(r2, 1022);
  mixin(assertString("tree.parentIndex(r11) == r1", "tree.parentIndex(r11)", "r11", "r1", "tree"));
  mixin(assertString("tree.parentIndex(r12) == r1", "tree.parentIndex(r12)", "r12", "r1", "tree"));
  mixin(assertString("tree.parentIndex(r21) == r2", "tree.parentIndex(r21)", "r21", "r2", "tree"));
  mixin(assertString("tree.parentIndex(r22) == r2", "tree.parentIndex(r22)", "r22", "r2", "tree"));
  mixin(assertString("tree.parentIndex(r1)  == root", "tree.parentIndex(r1)", "r1", "root", "tree"));
  mixin(assertString("tree.parentIndex(r2)  == root", "tree.parentIndex(r2)", "r2", "root", "tree"));
  mixin(assertString("tree.parentIndex(root)  == root", "tree.parentIndex(root)", "root", "tree"));
  
  mixin(assertString("tree.childIndex(root, 0) == r1", "tree.childIndex(root, 0)", "r1", "tree.get(root).childIndices", "tree"));
  mixin(assertString("tree.childIndex(root, 1) == r2", "tree.childIndex(root, 1)", "r2", "tree.get(root).childIndices", "tree"));
  mixin(assertString("tree.childIndex(r1, 0) == r11", "tree.childIndex(r1, 0)", "r11", "tree.get(r1).childIndices", "tree"));
  mixin(assertString("tree.childIndex(r1, 1) == r12", "tree.childIndex(r1, 1)", "r12", "tree.get(r1).childIndices", "tree"));
  mixin(assertString("tree.childIndex(r2, 0) == r21", "tree.childIndex(r2, 0)", "r22", "tree.get(r2).childIndices", "tree"));
  mixin(assertString("tree.childIndex(r2, 1) == r22", "tree.childIndex(r2, 1)", "r22", "tree.get(r2).childIndices", "tree"));
}

unittest { // furling
  auto tree = IntTree();
  TreeIndex root = tree.addRoot(1);
  TreeIndex r1 = tree.appendChild(tree.rootIndex, 2);
  TreeIndex r2 = tree.appendChild(tree.rootIndex, 3);
  TreeIndex r11 = tree.appendChild(r1, 4);
  TreeIndex r12 = tree.appendChild(r1, 5);
  TreeIndex r21 = tree.appendChild(r2, 6);
  TreeIndex r22 = tree.appendChild(r2, 7);
  
  auto sumBranch = (uint[] values, TreeIndex index) {
    IntNode* node = &tree.get(index);
    uint sum = node.value;
    foreach(uint v; values)
      sum += v;
    return sum; 
  };
  
  uint plusFurl1 = tree.furlBranch(r1, sumBranch);
  mixin(assertString("plusFurl1 == 11", "plusFurl1", "tree"));
  uint plusFurl2 = tree.furlBranch(r2, sumBranch);
  mixin(assertString("plusFurl2 == 16", "plusFurl2", "tree"));
  uint plusFurlRoot = tree.furlBranch(root, sumBranch);
  mixin(assertString("plusFurlRoot == 28", "plusFurlRoot", "tree"));
}


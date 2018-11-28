module ASTVisitor

//visit all subtrees, build a 'semantic' tree which enumerates all variables,
//and returns all ast nodes in a comparable manner (two if statements with equivalent
//conditions but different variables which are used in the same way throughout the file
//are shown in the 'semantic' tree as equivalent objects)

//We could do this by starting at the leaf nodes and working our way up in enumeration.
//This way we ensure the same variable has the same enumeration in different sub trees.

//We then hash each sub tree. We group all sub trees by hash, and use this information
//to find the number of clones, largest class, etc. We store the source location of these
//trees if we need to refer to their location, and exclude this from the hash.
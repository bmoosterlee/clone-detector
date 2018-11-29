module ASTVisitor

import lang::java::m3::AST;

//visit all subtrees, build a 'semantic' tree which enumerates all variables,
//and returns all ast nodes in a comparable manner (two if statements with equivalent
//conditions but different variables which are used in the same way throughout the file
//are shown in the 'semantic' tree as equivalent objects)

//We could do this by starting at the leaf nodes and working our way up in enumeration.
//This way we ensure the same variable has the same enumeration in different sub trees.

//We then hash each sub tree. We group all sub trees by hash, and use this information
//to find the number of clones, largest class, etc. We store the source location of these
//trees if we need to refer to their location, and exclude this from the hash.

//Refactor type1clonedetector to take in different methods than md5hash, such that type 1
//and type 2 clones use the same method, but different 'signatures'.
//type 3 clones can generate multiple signatures, basically type 2, but with a copy of
//the tree where one line is missing for each line. We preserve the source location at
//each of these copies, and throw them all into the group by.

public set[Declaration] toAST(loc project){
	return createAstFromEclipseProject(project);
}

public set[Declaration] toClasses(Declaration compilationUnit){
	accumulator = {};
	visit(compilationUnit){
		case name: \class(_,_ , _,_ ): accumulator += name;
    	case name: \class(_): accumulator += name;
	}
	return accumulator;
}

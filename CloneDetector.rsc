module CloneDetector

import ASTVisitor;
import lang::java::m3::AST;
import IO;

public map[str, set[loc]] detectTypeIClones(loc project){
	set[Declaration] myAST = toAST(project);
	set[Declaration] myClasses = {myClass | myCompilationUnit <- myAST, myClass <- toClasses(myCompilationUnit)};
	set[loc] myClassLocs = {toLoc(myClass) | myClass <- myClasses};
	map[loc, list[str]] myClassesWithContents = (myClass : readFileLines(myClass) | myClass <- myClassLocs);
	map[loc, str] myClassesWithConcatenatedContents = (myClass : flatten(myContents) | <myClass, myContents> <- myClassesWithContents);
	list[tuple[loc, str]] myClassesWithContentsAsList = toList(myClassesWithConcatenatedContents);
	list[tuple[str, loc]] myContentsWithLocs = flip(myClassesWithContentsAsList);
	map[str, set[loc]] myContentGroupsWithLocs = group(myContentsWithLocs);
	return myContentGroupWithLocs;
}

public loc toLoc(Declaration declaration){
	return declaration.decl;
}

public str flatten(list[str] myList){
	accumulator = "";
	for(str myLine <- myList){
		accumulator += myLine;
	}
	return accumulator;
}

public list[tuple[str, loc]] flip(list[tuple[loc, str]] myList){
	return [<y, x> | <x, y> <- myList];
}

public map[str, set[loc]] group(list[tuple[str, loc]] myList){
	set[str] keys = {};
	for(tuple[str, loc] x <- myList){
		str key = x[0];
		keys += key;
	}
	
	map[str, set[loc]] myMap = (key : {x[1] | x <- myList, x[0] == key} | key <- keys);
	return myMap;
}

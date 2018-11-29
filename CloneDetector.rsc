module CloneDetector

import ASTVisitor;
import lang::java::m3::AST;
import IO;
import Map;

public map[str, set[loc]] detectTypeIClones(set[loc] myClassLocs){
	list[tuple[str, loc]] myClassesWithContents = generateTypeICloneSignature(myClassLocs);
	map[str, set[loc]] myCloneClasses = groupClones(myClassesWithContents);
}

public map[str, set[loc]] detectTypeIIIClones(set[loc] myClassLocs){
	list[tuple[list[str], loc]] myClassesWithContents = generateTypeIIICloneSignature(myClassLocs);
	map[str, set[loc]] myCloneClasses = groupClones(myClassesWithContents);
}

public set[loc] projectToClassLocs(loc project){
	set[Declaration] myAST = toAST(project);
	set[Declaration] myClasses = {myClass | myCompilationUnit <- myAST, myClass <- toClasses(myCompilationUnit)};
	set[loc] myClassLocs = {toLoc(myClass) | myClass <- myClasses};
	return myClassLocs;
}

public map[str, set[loc]] groupClones(list[tuple[str, loc]] myContentsWithLocsAsList){
	map[str, set[loc]] myCloneClasses = group(myContentsWithLocsAsList);
	return myCloneClasses;
}

public list[tuple[str, loc]] generateTypeICloneSignature(set[loc] myClassLocs){
	map[loc, str] myClassesWithContents = (myClass : md5HashFile(myClass) | myClass <- myClassLocs);
	list[tuple[loc, str]] myClassesWithContentsAsList = toList(myClassesWithContents);
	list[tuple[str, loc]] myContentsWithLocs = flip(myClassesWithContentsAsList);
	return myContentsWithLocs;
}

public map[list[str], set[loc]] groupClones(list[tuple[list[str], loc]] myContentsWithLocsAsList){
	map[list[str], set[loc]] myCloneClasses = group(myContentsWithLocsAsList);
	return myCloneClasses;
}

public list[tuple[list[str], loc]] generateTypeIIICloneSignature(set[loc] myClassLocs){
	map[loc, list[str]] classesWithContents =  (myClass : readFileLines(myClass) | myClass <- myClassLocs);
	map[loc, list[list[str]]] classesWithWindows = (myClass : calculateWindows(classesWithContents[myClass]) | myClass <- classesWithContents);
	map[loc, list[list[list[str]]]] classesWithMutationsPerWindow = (myClass : calculateMutations(classesWithWindows[myClass]) | myClass <- classesWithWindows);
	map[loc, list[list[str]]] classesWithMutations = (myClass : myMutation | myClass <- classesWithMutationsPerWindow, myMutation <- classesWithMutationsPerWindow[myClass]);
	list[tuple[loc, list[list[str]]]] classesWithMutationsAsList = [<myClass, classesWithMutations[myClass]> | myClass <- classesWithMutations];
	list[tuple[list[list[str]], loc]] mutationsWithClassAsList = flip(classesWithMutationsAsList);
	list[tuple[list[str], loc]] mutationWithClassAsList = [<mutation, mutationsWithClass[1]> | mutationsWithClass <- mutationsWithClassAsList, mutation <- mutationsWithClass[0]];
	return mutationWithClassAsList;
}

public list[list[str]] calculateWindows(list[str] myContents){
	list[list[str]] accumulator;
	for(windowSize <- [6..size(myContents)]){
		for(sourceLineIndex <- [0..(size(myContents)-windowSize)]){
			accumulator += slice(myContents, sourceLineIndex, windowSize);
		}
	}
	return accumulator;
}

public list[list[list[str]]] calculateMutations(list[list[str]] windows){
	return [mutate(myWindow) | myWindow <- windows];
}

public list[list[str]] mutate(list[str] window){
	list[list[str]] myMutations = [window];
	if(size(window)>6){
		for(i <- [1..(size(window)-1)]){
			myMutations += delete(window, i);
		}
	}
	return myMutations;
}

public loc toLoc(Declaration declaration){
	return declaration.decl;
}

public list[tuple[str, loc]] flip(list[tuple[loc, str]] myList){
	return [<y, x> | <x, y> <- myList];
}

public list[tuple[list[list[str]], loc]] flip(list[tuple[loc, list[list[str]]]] myList){
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

public map[list[str], set[loc]] group(list[tuple[list[str], loc]] myList){
	set[list[str]] keys = {};
	for(tuple[list[str], loc] x <- myList){
		list[str] key = x[0];
		keys += key;
	}
	
	map[list[str], set[loc]] myMap = (key : {x[1] | x <- myList, x[0] == key} | key <- keys);
	return myMap;
}

public void analyze(loc project){
	set[loc] myClassLocs = projectToClassLocs(project);
	detectTypeIClones(myClassLocs);
	detectTypeIIIClones(myClassLocs);
	
}











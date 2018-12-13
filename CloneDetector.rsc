module CloneDetector

import ASTVisitor;
import lang::java::m3::AST;
import IO;
import List;
import Map;
import Set;

public map[list[str], set[loc]] detectTypeIClones(set[loc] myClassLocs){
	println("stage I GENERATE SIGNATURES");
	list[tuple[list[str], loc]] myClassesWithContents = generateTypeICloneSignature(myClassLocs);
	println("stage I GROUP");
	map[list[str], set[loc]] myCloneClasses = groupClones(myClassesWithContents);
	return myCloneClasses;
}

public map[list[str], set[loc]] detectTypeIIClones(set[loc] myClassLocs){
	println("stage II GENERATE SIGNATURES");
	list[tuple[Declaration, loc]] myClassesWithContents = generateTypeIICloneSignature(myClassLocs);
	println("stage II GROUP");
	map[Declaration, set[loc]] myCloneClasses = groupClones(myClassesWithContents);
	map[list[str], set[loc]] myCloneClassesAsStrings = (readFileLines(toLoc(key)) : myCloneClasses[key] | key <- myCloneClasses);
	return myCloneClassesAsStrings;
}

public map[Declaration, set[loc]] groupClones(list[tuple[Declaration, loc]] myContentsWithLocsAsList){
	map[Declaration, set[loc]] myCloneClasses = group(myContentsWithLocsAsList);
	return (x : myCloneClasses[x] | x <- myCloneClasses, size(myCloneClasses[x])>1);
}

public map[Declaration, set[loc]] group(list[tuple[Declaration, loc]] myList){
	set[Declaration] keys = {};
	for(tuple[Declaration, loc] x <- myList){
		Declaration key = x[0];
		keys += key;
	}
	
	map[Declaration, set[loc]] myMap = (key : {x[1] | x <- myList, x[0] == key} | key <- keys);
	return myMap;
}

public map[list[str], set[loc]] detectTypeIIIClones(set[loc] myClassLocs){
	println("stage III GENERATE SIGNATURES");
	list[tuple[list[str], loc]] myClassesWithContents = generateTypeIIICloneSignature(myClassLocs);
	println("stage III GROUP");
	map[list[str], set[loc]] myCloneClasses = groupClones(myClassesWithContents);
	return myCloneClasses;
}

public set[loc] projectToClassLocs(loc project){
	set[loc] accumulator = {};
	set[loc] unfinished = {project};
	while(!isEmpty(unfinished)){
		tuple[loc, set[loc]] foundTuple = takeOneFrom(unfinished);
		loc found = foundTuple[0];
		unfinished = foundTuple[1];
		if(isFile(found)){
			accumulator += found;
		} else if(isDirectory(found)){
			unfinished += {x | x <- found.ls};
		}
	}
	return accumulator;
}

public map[list[str], set[loc]] groupClones(list[tuple[list[str], loc]] myContentsWithLocsAsList){
	map[list[str], set[loc]] myCloneClasses = group(myContentsWithLocsAsList);
	return (x : myCloneClasses[x] | x <- myCloneClasses, size(myCloneClasses[x])>1);
}

public list[tuple[list[str], loc]] generateTypeICloneSignature(set[loc] myClassLocs){
	println("stage I 1");
	map[loc, list[str]] classesWithContents =  (myClass : readFileLines(myClass) | myClass <- myClassLocs);
	println("stage I 2");
	map[loc, list[list[str]]] classesWithWindows = (myClass : calculateWindows(classesWithContents[myClass]) | myClass <- classesWithContents);
	println("stage I 3");
	list[tuple[loc, list[str]]] classWithWindowAsList = [<myClass, myWindow> | myClass <- classesWithWindows, myWindow <- classesWithWindows[myClass]];
	println("stage I 4");
	list[tuple[list[str], loc]] windowWithClassAsList = flip(classWithWindowAsList);
	println("stage I 5");
	return windowWithClassAsList;
}

public list[tuple[Declaration, loc]] generateTypeIICloneSignature(set[loc] myClassLocs){
	println("stage II 1");
	map[loc, set[Declaration]] classesWithContents =  (myClass : toAST(myClass) | myClass <- myClassLocs);
	//Write method which builds all the sub graphs from an ast
	println("stage II 2");
	map[loc, list[Declaration]] classesWithAdjustedAsts = (myClass : [generateTypeIICloneSignature(myAst) | myAst <- classesWithContents[myClass]] | myClass <- classesWithContents);
	println("stage II 3");
	list[tuple[loc, list[Declaration]]] classWithAstsAsList = [<myClass, classesWithAdjustedAsts[myClass]> | myClass <- classesWithAdjustedAsts];
	println("stage II 4");
	list[tuple[loc, Declaration]] astsWithClassAsList = [<x, yy> | <x, y> <- classWithAstsAsList, yy <- y];
	println("stage II 5");
	list[tuple[Declaration, loc]] astWithClassAsList = flip(astsWithClassAsList);
	return astWithClassAsList;
}

public list[tuple[Declaration, loc]] flip(list[tuple[loc, Declaration]] myList){
	return [<y, x> | <x, y> <- myList];
}

public list[tuple[list[str], loc]] generateTypeIIICloneSignature(set[loc] myClassLocs){
	println("stage III 1");
	map[loc, list[str]] classesWithContents =  (myClass : readFileLines(myClass) | myClass <- myClassLocs);
	println("stage III 2");
	map[loc, list[list[str]]] classesWithWindows = (myClass : calculateWindows(classesWithContents[myClass]) | myClass <- classesWithContents);
	println("stage III 3");
	map[loc, list[list[list[str]]]] classesWithMutationsPerWindow = (myClass : calculateMutations(classesWithWindows[myClass]) | myClass <- classesWithWindows);
	println("stage III 4");
	list[tuple[loc, list[str]]] classWithMutationAsList = [<myClass, myMutation> | myClass <- classesWithMutationsPerWindow, myWindow <- classesWithMutationsPerWindow[myClass], myMutation <- myWindow];
	println("stage III 5");
	list[tuple[list[str], loc]] mutationWithClassAsList = flip(classWithMutationAsList);
	println("stage III 6");
	return mutationWithClassAsList;
}

public str concat(list[str] myList){
	str accumulator = "";
	for(str myStr <- myList){
		accumulator+=myStr+"\n";
	}
	return accumulator;
}

public list[list[str]] calculateWindows(list[str] myContents){
	list[list[str]] accumulator = [];
	for(int windowSize <- [6]){
		for(sourceLineIndex <- [0..(size(myContents)-windowSize+1)]){
			accumulator += [[val | val <- slice(myContents, sourceLineIndex, windowSize)]];
		}
	}
	return accumulator;
}

public list[list[list[str]]] calculateMutations(list[list[str]] myWindows){
	return [mutate(myWindow) | myWindow <- myWindows];
}

public list[list[str]] mutate(list[str] window){
	list[list[str]] myMutations = [window];
	for(i <- [1..(size(window)-1)]){
		myMutations += [delete(window, i)];
	}
	return myMutations;
}

public loc toLoc(Declaration myDeclaration){
	return myDeclaration.decl;
}

public list[tuple[str, loc]] flip(list[tuple[loc, str]] myList){
	return [<y, x> | <x, y> <- myList];
}

public list[tuple[list[str], loc]] flip(list[tuple[loc, list[str]]] myList){
	return [<y, x> | <x, y> <- myList];
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

	writeToFile("I", detectTypeIClones(myClassLocs), |project://CloneDetector/out/typeIclone.txt|);
	writeToFile("II", detectTypeIIClones(myClassLocs), |project://CloneDetector/out/typeIIclone.txt|);
	writeToFile("III", detectTypeIIIClones(myClassLocs), |project://CloneDetector/out/typeIIIclone.txt|);
}

public void writeToFile(str cloneType, map[list[str], set[loc]] cloneClassMap, loc myOutputLoc){
	println("started detecting type " + cloneType + " clones");
	set[list[str]] cloneClasses = {x | x <- cloneClassMap};
	println("started writing type " + cloneType + " clones to file");
	writeFile(myOutputLoc, "");
	int counter = 0;
	appendToFile(myOutputLoc, "start of clone class: ");
	appendToFile(myOutputLoc, counter);
	appendToFile(myOutputLoc, "\n");
	for(list[str] cloneClass <- cloneClasses){
		for(str cloneLine <- cloneClass){
			appendToFile(myOutputLoc, cloneLine + "\n");
		}
		counter += 1;
		appendToFile(myOutputLoc, "\n");
	}
}

public loc getProjectLarge(){
	return |project://hsqldb2/src/org/hsqldb|;
}

public loc getProjectSmall(){
	return |project://smallsql/src/smallsql/database|;
}









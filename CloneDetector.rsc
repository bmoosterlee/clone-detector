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

public list[tuple[list[str], loc]] generateTypeIIICloneSignature(set[loc] myClassLocs){
	println("stage III 1");
	map[loc, list[str]] classesWithContents =  (myClass : readFileLines(myClass) | myClass <- myClassLocs);
	println("stage III 2");
	map[loc, list[list[str]]] classesWithWindows = (myClass : calculateWindows(classesWithContents[myClass]) | myClass <- classesWithContents);
	println("stage III 3");
	map[loc, list[list[list[str]]]] classesWithMutationsPerWindow = (myClass : calculateMutations(classesWithWindows[myClass]) | myClass <- classesWithWindows);
	println("stage III 4");
	//concat mutations earlier to improve legibility
	map[loc, list[list[str]]] classesWithMutations = (myClass : myMutation | myClass <- classesWithMutationsPerWindow, myMutation <- classesWithMutationsPerWindow[myClass]);
	println("stage III 5");
	list[tuple[loc, list[str]]] classWithMutationAsList = [<myClass, myMutation> | myClass <- classesWithMutations, myMutation <- classesWithMutations[myClass]];
	println("stage III 6");
	list[tuple[list[str], loc]] mutationWithClassAsList = flip(classWithMutationAsList);
	println("stage III 7");
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
		for(sourceLineIndex <- [0..(size(myContents)-windowSize)]){
			accumulator += [slice(myContents, sourceLineIndex, windowSize)];
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
			myMutations += [delete(window, i)];
		}
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

	println("started detecting type I clones");
	set[list[str]] typeICloneClasses = {x | x <- detectTypeIClones(myClassLocs)};
	loc myProjectLoc = |project://CloneDetector/out/typeIclone.txt|;
	println("started writing type I clones to file");

	writeFile(myProjectLoc, "");
	int counter = 0;
	appendToFile(myProjectLoc, "start of clone class: \n");
	appendToFile(myProjectLoc, counter);
	appendToFile(myProjectLoc, "\n");
	for(list[str] cloneClass <- typeICloneClasses){
		for(str cloneLine <- cloneClass){
			appendToFile(myProjectLoc, cloneLine + "\n");
		}
		counter += 1;
	}
	
	println("started detecting type III clones");
	set[list[str]] typeIIICloneClasses = {x | x <- detectTypeIIIClones(myClassLocs)};
	loc myProjectLoc2 = |project://CloneDetector/out/typeIIIclone.txt|;
	println("started writing type III clones to file");
	
	writeFile(myProjectLoc2, "");
	counter = 0;
	appendToFile(myProjectLoc2, "start of clone class: ");
	appendToFile(myProjectLoc2, counter);
	appendToFile(myProjectLoc2, "\n");
	for(list[str] cloneClass <- typeIIICloneClasses){
		for(str cloneLine <- cloneClass){
			appendToFile(myProjectLoc2, cloneLine + "\n");
		}
		counter += 1;
	}
}

public loc getProjectLarge(){
	return |project://hsqldb2/src/org/hsqldb|;
}

public loc getProjectSmall(){
	return |project://smallsql/src/smallsql/database|;
}









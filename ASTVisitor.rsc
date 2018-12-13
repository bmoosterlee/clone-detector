module ASTVisitor

import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import util::Math;

public set[Declaration] toAST(loc project){
	return createAstsFromEclipseProject(project, true);
}

public set[Declaration] toClasses(Declaration compilationUnit){
	accumulator = {};
	visit(compilationUnit){
		case name: \class(_,_ , _,_ ): accumulator += name;
    	case name: \class(_): accumulator += name;
	}
	return accumulator;
}

public Declaration generateTypeIICloneSignature(Declaration myAst){
	map[str, str] knownIdentifiers = ();
	int enumeratorCounter = 0;
	
	//Replace all values with string "VALUE"
	//Replace all identifier with the enumeration and the word "identifier"
	return visit(myAst){
  		case \variable(str name, int extraDimensions): {
  			if(name in knownIdentifiers){
  				insert \variable(knownIdentifiers[name], extraDimensions);
  			} else {
	  			str newName = "IDENTIFIER " + toString(enumeratorCounter);
	  			knownIdentifiers += (name : newName);
	  			enumeratorCounter += 1;
	  			insert \variable(newName, extraDimensions);
  			}
  		}
    	case \variable(str name, int extraDimensions, Expression \initializer): {
  			if(name in knownIdentifiers){
  				insert \variable(knownIdentifiers[name], extraDimensions, \initializer);
  			} else {
	  			str newName = "IDENTIFIER " + toString(enumeratorCounter);
	  			knownIdentifiers += (name : newName);
	  			enumeratorCounter += 1;
	  			insert \variable(newName, extraDimensions, \initializer);
  			}
    	}
	}
}

package ;

import neko.Lib;
import sys.io.Process;

/**
 * ...
 * @author Martin Jonasson, m@grapefrukt.com
 */

 typedef Library = {
	name:String, 
	version:String,
	?path:String,
	?isGit:Bool,
	?isDirty:Bool,
	?gitVersion:String,
 }

class Main {
	
	static function main() {
		echo("buildtag   date:    " + Date.now());
		echo("");
		
		var libs = parseLibs(getOutput("haxelib", ["list"]));
		checkGit(libs);
		
		printLibs(libs);
	}
	
	private static function printLibs(libs:Array<Library>) {
		for (lib in libs) {
			echo(lib.name);
			echo("    version: " + lib.version);
			if (lib.version == "dev") {
				echo("    path:    " + lib.path);
				echo("    git:     " + lib.gitVersion + (lib.isDirty ? " (DIRTY)" : ""));
			}
			echo("");
		}
	}
	
	private static function checkGit(libs:Array<Library>) {
		// this function will change the working directory, so we store where we started before
		var hwd = Sys.getCwd();
		for (lib in libs) {
			if (lib.version == "dev") {
				// jump to the library directory
				Sys.setCwd(lib.path);
				// check if it's a git repo
				lib.isGit = getOutput("git", ["rev-parse",  "--is-inside-work-tree"])[0] == "true";
				
				// if it's a git repo, we check if it's dirty
				if (lib.isGit) {
					lib.isDirty = getOutput("git", ["status", "--porcelain"])[0] != "";
					// and finally, we get the git version string
					lib.gitVersion = getOutput("git", ["rev-parse", "HEAD"])[0];
				}
			}
		}
		// go back to the original working directory
		Sys.setCwd(hwd);
	}
	
	private static function parseLibs(data:Array<String>):Array<Library> {
		var libs:Array<Library> = [];
		
		// parses out library name and currently active version
		var r = ~/^(.*)?:.*?\[(.*?)\]/;
		
		// run the regex on all the rows of data
		for (row in data) {
			if (r.match(row)) libs.push( { name : r.matched(1), version : r.matched(2) } );
		}
		
		for (lib in libs) {
			// checks if the lib has the letters dev at the begginging of the version string
			if (lib.version.indexOf("dev") == 0) {
				// if that's the case, parse out the folder the dev version is in
				lib.path = lib.version.substr(4);
				// and set the version to just "dev"
				lib.version = "dev";
			}
		}
		
		return libs;
	}
	
	private static function getOutput(process:String, ?args:Array<String>) {
		var process = new Process(process, args != null ? args : []);
		
		var result:Array<String> = [];
		
		// try to read the stdout, this crashes if there's nothing to read, hence the try/catch
		var line = " ";
		while (line != "") {
			line = "";
			try {
				line = process.stdout.readLine();
			} catch (e:Dynamic) {
				// call failed, not much to do about it
			}
			if (line != "") result.push(line);
		}
		
		// cheating a bit here, if the result turns out to be empty, return an array with an empty string instead
		return result.length > 0 ? result : [""];
	}
	
	private static function echo(str:String) {
		neko.Lib.print(str + "\n");
	}
	
}
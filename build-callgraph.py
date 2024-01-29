#!/usr/bin/env python3

# Usage:
# python3 build-callgraph.py <class.java>
# or
# python3 build-callgraph.py <class1> <class2> ... <classN>
# where class1 is assumed to be the entry point
# the jar file will be created with all classes in the same directory as the first class

# It is directory-independent since we translate paths to absolute paths.
# Depends on:
# - WALA-callgraph submodule
# - gradle
# - javac
# - jar


import logging
import subprocess
import sys
from os import path
from typing import List

logging.basicConfig(level=logging.INFO)
show_output = logging.getLogger().level <= logging.DEBUG

sources: List[str] = sys.argv[1:]
assert(len(sources) > 0)

def run(*args, **kwargs):
	cmd = args[0]
	if isinstance(cmd, list):
		cmd = " ".join(cmd)
	logging.debug(cmd)

	if show_output:
		proc = subprocess.run(*args, **kwargs, capture_output=False)
	else:
		proc = subprocess.run(*args, **kwargs, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

logging.info("Compiling %s", sources)
run(["javac"] + sources)

def java_to_ext(java: str, ext: str) -> str:
	return path.splitext(java)[0] + "." + ext

classes = [java_to_ext(s, "class") for s in sources]
main_class = classes[0]

jar = java_to_ext(main_class, "jar")

logging.info("Building %s with %s", jar, classes)

# compose jar command to switch to main classes' directory
# and then add the class files;
# simply passing paths to jar causes jar to embed the directory structure of path in the jar file, e.g.:
# jar usertest/HelloWorld.class will embed the directory usertest in the jar file

command = ["jar", "cf", jar]
for c in classes:
	command.extend(["-C", path.dirname(c), path.basename(c)])
logging.debug(" ".join(command))
run(command)

run("./gradlew compileJava", shell=True, cwd="WALA-callgraph")

jar = path.abspath(jar)
callgraph = path.abspath(java_to_ext(main_class, "callgraph"))

logging.info("Building callgraph for %s in %s", jar, callgraph)
run(["./run.py", callgraph, jar], cwd="WALA-callgraph")

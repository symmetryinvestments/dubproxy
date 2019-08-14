module dubproxy.git;

import std.array : empty;
import std.algorithm.iteration : filter, splitter;
import std.exception : enforce;
import std.format : format;
import std.process : executeShell;
import std.string : split, strip;

@safe:

struct TagReturn {
	string hash;
	string tag;
}

TagReturn[] getTags(string path) {
	const toExe = format!"git ls-remote --tags %s"(path);
	auto rslt = executeShell(toExe);
	enforce(rslt.status == 0, format!"'%s' returned with '%d' 0 was expected"(
			toExe, rslt.status));

	TagReturn[] ret;
	foreach(line; rslt.output.splitter("\n").filter!(line => !line.empty)) {
		string[] lineSplit = line.split('\t');
		enforce(lineSplit.length == 2, format!
				"Line '%s' split incorrectly in '%s'"(line, lineSplit));

		ret ~= TagReturn(lineSplit[0].strip(" \t\n\r"),
					lineSplit[1].strip(" \t\n\r"));
	}
	return ret;
}

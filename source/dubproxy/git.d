module dubproxy.git;

import std.array : empty;
import std.algorithm.iteration : filter, splitter;
import std.algorithm.searching : startsWith;
import std.exception : enforce;
import std.file : exists, isDir, mkdirRecurse, rmdirRecurse, getcwd, chdir,
	   readText;
import std.path : absolutePath;
import std.stdio : File;
import std.format : format;
import std.process : executeShell;
import std.typecons : Flag;
import std.string : split, strip;

import dubproxy.options;

@safe:

struct TagReturn {
	string hash;
	string tag;

	string getVersion() const {
		import std.string : lastIndexOf;

		enforce(!this.tag.empty, "Can not compute version of empty tag");
		const idx = this.tag.lastIndexOf('/');
		if(idx == -1) {
			return this.tag;
		}
		return this.tag[idx + 1 .. $];
	}
}

string getHashFromVersion(const(TagReturn[]) tags, string ver) pure {
	import std.algorithm.searching : endsWith;
	foreach(it; tags) {
		if(it.tag.endsWith(ver)) {
			return it.hash;
		}
	}
	return "";
}

enum TagKind {
	branch,
	pull,
	tags,
	all
}

TagReturn[] getTags(string path, ref const(DubProxyOptions) options) {
	return getTags(path, TagKind.tags, options);
}

TagReturn[] getTags(string path, TagKind tk, ref const(DubProxyOptions) options)
{
	import std.algorithm.searching : canFind;

	const toExe = tk == TagKind.tags
		? format!`%s ls-remote --tags --sort="-version:refname" %s`(
				options.pathToGit, path
			)
		: format!`%s ls-remote %s`(options.pathToGit, path);

	const kindFilter = tk == TagKind.branch ? "heads"
		: tk == TagKind.pull ? "pull"
		: tk == TagKind.tags ? "tags" : "";

	auto rslt = executeShell(toExe);
	enforce(rslt.status == 0, format!
			"'%s' returned with '%d' 0 was expected output '%s'"(
			toExe, rslt.status, rslt.output));

	TagReturn[] ret;
	foreach(line; rslt.output.splitter("\n")
			.filter!(line => !line.empty)
			.filter!(line => !canFind(line, "^{}"))
			.filter!(line => kindFilter.empty || line.canFind(kindFilter)))
	{
		string[] lineSplit = line.split('\t');
		enforce(lineSplit.length == 2, format!
				"Line '%s' split incorrectly in '%s'"(line, lineSplit));

		ret ~= TagReturn(lineSplit[0].strip(" \t\n\r"),
					lineSplit[1].strip(" \t\n\r"));
	}
	return ret;
}

alias LocalGit = Flag!"LocalGit";

void cloneBare(string path, const LocalGit lg, string destDir,
		ref const(DubProxyOptions) options)
{
	const bool e = exists(destDir);
	enforce(!e || options.ovrGF == OverrideGitFolder.yes, format!(
			"Path '%s' exist and override flag was not passed")(destDir));

	if(e) {
		() @trusted { rmdirRecurse(destDir); }();
	}

	const toExe = format!`%s clone --bare%s %s %s`(options.pathToGit,
			lg == LocalGit.yes ? " -l" : "", path, destDir);
	auto rslt = executeShell(toExe);
	enforce(rslt.status == 0, format!
			"'%s' returned with '%d' 0 was expected output '%s'"(
			toExe, rslt.status, rslt.output));
}

void createWorkingTree(string clonedGitPath, const(TagReturn) tag,
		string packageName, string destDir, ref const(DubProxyOptions) options)
{
	const ver = tag.getVersion();
	const verTag = ver.startsWith("v") ? ver[1 .. $] : ver;
	const absGitPath = absolutePath(clonedGitPath);
	const absDestDir = absolutePath(destDir);
	const rsltPath = format!"%s/%s-%s/%s"(absDestDir, packageName, verTag,
			packageName);

	const bool e = exists(rsltPath);
	enforce(!e || options.ovrWTF == OverrideWorkTreeFolder.yes, format!(
			"Path '%s' exist and override flag was not passed")(rsltPath));

	if(e) {
		() @trusted { rmdirRecurse(rsltPath); }();
	} else {
		mkdirRecurse(rsltPath);
	}

	const string cwd = getcwd();
	scope(exit) {
		chdir(cwd);
		enforce(getcwd() == cwd, format!"Failed to paths to '%s' cwd '%s'"(cwd,
				getcwd()));
	}

	chdir(absGitPath);
	enforce(getcwd() == absGitPath,
			format!"Failed to paths to '%s'"(absGitPath));

	const toExe = format!"%s worktree add -f %s %s"(options.pathToGit, rsltPath,
			ver);
	auto rslt = executeShell(toExe);
	enforce(rslt.status == 0, format!
			"'%s' returned with '%d' 0 was expected output '%s'"(
			toExe, rslt.status, rslt.output));

	insertVersionIntoDubFile(rsltPath, verTag, options);
}

void insertVersionIntoDubFile(string packageDir, string ver,
		ref const(DubProxyOptions) options)
{
	const js = format!"%s/dub.json"(packageDir);
	const jsE = exists(js);
	const pkg = format!"%s/package.json"(packageDir);
	const pkgE = exists(pkg);
	const sdl = format!"%s/dub.sdl"(packageDir);
	const sdlE = exists(sdl);
	const cVer = ver.startsWith("v") ? ver[1 .. $] : ver;
	if(jsE) {
		insertVersionIntoDubJsonFile(js, cVer);
	} else if(sdlE) {
		insertVersionIntoDubSDLFile(sdl, cVer, options);
	} else if(pkgE) {
		insertVersionIntoDubJsonFile(pkg, cVer);
	} else {
		enforce(false, format!"could not find a dub.{json,sdl} file in '%s'"
				(packageDir));
	}
}

void insertVersionIntoDubJsonFile(string fileName, string ver) {
	import std.json : JSONValue, parseJSON;
	JSONValue j = parseJSON(readText(fileName));
	j["version"] = ver;

	auto f = File(fileName, "w");
	f.write(j.toPrettyString());
	f.writeln();
}

void insertVersionIntoDubSDLFile(string fileName, string ver,
		ref const(DubProxyOptions) options)
{
	import std.path : dirName;
	const pth = dirName(fileName);
	const string cwd = getcwd();
	scope(exit) {
		chdir(cwd);
	}
	chdir(pth);
	const toExe = format!`%s convert --format=json`(options.pathToDub);

	auto rslt = executeShell(toExe);
	enforce(rslt.status == 0, format!(
			"dub failed with code '%s' and output '%s' to convert dub.sdl to "
			~ "dub.json with cmd '%s'")(rslt.status, rslt.output, toExe));

	const jsFn = pth ~ "/dub.json";
	insertVersionIntoDubJsonFile(jsFn, ver);
}

enum PathKind {
	remoteGit,
	localGit,
	folder
}

PathKind getPathKind(string path) {
	import url;
	if(exists(path) && isDir(path) && exists(path ~ "/.git")) {
		return PathKind.localGit;
	} else if(exists(path) && isDir(path) && !exists(path ~ "/.git")) {
		return PathKind.folder;
	}

	URL u;
	if(tryParseURL(path, u)) {
		return PathKind.remoteGit;
	}

	throw new Exception(format!"Couldn't determine PathKind for '%s'"(path));
}

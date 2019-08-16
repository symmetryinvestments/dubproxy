module options;

import std.getopt;
import dubproxy.options : DubProxyOptions;

@safe:

struct DubProxyCliOptions {
	import dubproxy.git : TagKind;
	DubProxyOptions libOptions;

	bool mirrorCodeDlang;
	string mirrorFilename = "code.json";
	string[] packages;
	string proxyFile = "dubproxy.json";
	string packageFolder = getDefaultPackageFolder();
	string gitFolder = getDefaultPackageFolder();

	bool dummyDubProxy;
	string dummyDubProxyPath = ".";

	string showTagsPath;
	TagKind tagKind = TagKind.all;

	bool cloneAll;
	bool cloneAllNoTerminal;
}

private DubProxyCliOptions __options;

ref DubProxyCliOptions writeAbleOptions() {
	return __options;
}

@property ref const(DubProxyCliOptions) options() {
	return __options;
}

string getDefaultPackageFolder() pure {
	version(Posix) {
		return "~/.dub/packages/";
	} else version(Windows) {
		return `%APPDATA%\dub\packages\`;
	} else {
		static assert(false, "Unsupported platform");
	}
}

string getDefaultGitFolder() pure {
	version(Posix) {
		return "~/.dub/DubProxyGits/";
	} else version(Windows) {
		return `%APPDATA%\dub\DubProxyGits\`;
	} else {
		static assert(false, "Unsupported platform");
	}
}


GetoptResult parseOptions(ref string[] args) {
	auto helpInformation = getopt(args,
		"m|mirror",
		"Get a list of packages currently available on code.dlang.org"
		~ "\n\t\t\tand store a file specified in \"n|mirrorFileName\"",
		&writeAbleOptions().mirrorCodeDlang,

		"n|mirrorFileName",
		"The filename where to store the packages available on code.dlang.org",
		&writeAbleOptions().mirrorFilename,

		"d|dubPath",
		"The path to the dub executable",
		&writeAbleOptions().libOptions.pathToDub,

		"p|gitPath",
		"The path to the git executable",
		&writeAbleOptions().libOptions.pathToGit,

		"f|gitFolder",
		"The path where the gits get cloned to",
		&writeAbleOptions().gitFolder,

		"overrideGit",
		"Allow to override the git folder of cloned packages",
		&writeAbleOptions().libOptions.ovrGF,

		"overrideTree",
		"Allow to override the git worktree folder of cloned package version",
		&writeAbleOptions().libOptions.ovrWTF,

		"g|get",
		"Get a precific package. \"-g dub\" will fetch dub and create"
		~ "\n\t\t\tfolders for all version tags for dub. \"-g dub:1.1.0\" will "
		~ "\n\t\t\ttry to get dub and create a package for v1.1.0. "
		~ "\n\t\t\t\"g dub:~master\" will try get dub and create a package for "
		~ "\n\t\t\t~master",
		&writeAbleOptions().packages,

		"i|proxyFile",
		"The filename of the dubproxy file to search packages in",
		&writeAbleOptions().proxyFile,

		"o|packagesFolder",
		"The path where packages should be stored",
		&writeAbleOptions().packageFolder,

		"dummy",
		"Generate a empty dubproxy.json file",
		&writeAbleOptions().dummyDubProxy,

		"dummyPath",
		"Path to the folder where to create the dummy dubproxy.json file",
		&writeAbleOptions().dummyDubProxyPath,

		"t|tags",
		"Show tags for passed dirpath or url",
		&writeAbleOptions().showTagsPath,

		"k|tagsKind",
		"Limit tags to a specific kind of tags",
		&writeAbleOptions().tagKind,

		"a|cloneAll",
		"Clone or fetch all packages provided in \"i|input\"",
		&writeAbleOptions().cloneAll,

		"u|noUserInteraction",
		"Run git without user interaction",
		&writeAbleOptions().libOptions.noUserInteraction
		);

	return helpInformation;
}

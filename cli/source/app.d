import std.stdio;

import std.getopt;

import dubproxy;
import options;

int main(string[] args) {
	auto helpInformation = getopt(args,
		"m|mirror",
		"Get a list of packages currently available on code.dlang.org "
		~ "and store a file specified in \"n|mirrorFileName\"",
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

		"overrideGit",
		"Allow to override the git folder of cloned packages",
		&writeAbleOptions().libOptions.ovrGF,

		"overrideTree",
		"Allow to override the git worktree folder of cloned package version",
		&writeAbleOptions().libOptions.ovrWTF,

		"g|get",
		"Get a precific package",
		&writeAbleOptions().packages,

		"i|proxyFile",
		"The filename of the dubproxy file to search packages in",
		&writeAbleOptions().proxyFile,

		"o|packagesFolder",
		"The path to where packages should be stored",
		&writeAbleOptions().packageFolder

		);

	if(helpInformation.helpWanted) {
		defaultGetoptPrinter("Dubproxy is a tool to make dub work with "
			~ "private repos and to bypass code.dlang.org to fetch packages",
			helpInformation.options);
		return 0;
	}

	return 0;
}

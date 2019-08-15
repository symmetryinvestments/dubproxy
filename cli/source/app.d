import std.stdio;

import std.getopt;

import dubproxy;
import opts = options;

int main(string[] args) {
	auto helpInformation = getopt(args,
		"m|mirror",
		"Get a list of packages currently available on code.dlang.org "
		~ "and store a file specified in \"n|mirrorFileName\"",
		&opts.writeAbleOptions().mirrorCodeDlang,

		"n|mirrorFileName",
		"The filename where to store the packages available on code.dlang.org",
		&opts.writeAbleOptions().mirrorFilename,

		"d|dubPath",
		"The path to the dub executable",
		&opts.writeAbleOptions().libOptions.pathToDub,

		"p|gitPath",
		"The path to the git executable",
		&opts.writeAbleOptions().libOptions.pathToGit,

		"overrideGit",
		"Allow to override the git folder of cloned packages",
		&opts.writeAbleOptions().libOptions.ovrGF,

		"overrideTree",
		"Allow to override the git worktree folder of cloned package version",
		&opts.writeAbleOptions().libOptions.ovrWTF,

		"g|get",
		"Get a precific package",
		&opts.writeAbleOptions().packages,

		"i|proxyFile",
		"The filename of the dubproxy file to search packages in",
		&opts.writeAbleOptions().proxyFile,

		"o|packagesFolder",
		"The path where packages should be stored",
		&opts.writeAbleOptions().packageFolder,

		"dummy",
		"Generate a empty dubproxy.json file",
		&opts.writeAbleOptions().dummyDubProxy,

		"dummyPath",
		"Path to the folder where to create the dummy dubproxy.json file",
		&opts.writeAbleOptions().dummyDubProxyPath,
		);

	if(helpInformation.helpWanted) {
		defaultGetoptPrinter("Dubproxy is a tool to make dub work with "
			~ "private repos and to bypass code.dlang.org to fetch packages",
			helpInformation.options);
		return 0;
	}

	if(opts.options.dummyDubProxy) {
		DubProxyFile dpf;
		toFile(dpf, opts.options.dummyDubProxyPath ~ "/dubproxy.json");
	}

	if(opts.options.mirrorCodeDlang) {
		DubProxyFile dpf = getCodeDlangOrgCopy();
		toFile(dpf, opts.options.mirrorFilename);
	}

	DubProxyFile dpf = fromFile(opts.options.proxyFile);
	foreach(it; opts.options.packages) {
		writeln(it);
	}

	return 0;
}

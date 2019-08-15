import std.array : empty;
import std.stdio;
import std.getopt;

import dubproxy;
import dubproxy.git;

import opts = options;

int main(string[] args) {
	auto helpInformation = getopt(args,
		"m|mirror",
		"Get a list of packages currently available on code.dlang.org"
		~ "\n\t\t\tand store a file specified in \"n|mirrorFileName\"",
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
		"Get a precific package. \"-g dub\" will fetch dub and create"
		~ "\n\t\t\tfolders for all version tags for dub. \"-g dub:1.1.0\" will "
		~ "\n\t\t\ttry to get dub and create a package for v1.1.0. "
		~ "\n\t\t\t\"g dub:~master\" will try get dub and create a package for "
		~ "\n\t\t\t~master",
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
		const GetSplit s = splitGet(it);
		const gitDestDir = getPackage(dpf, s.pkg);
		TagReturn[] allTags = getTags(gitDestDir, TagKind.all,
				opts.options.libOptions);
		foreach(tag; allTags) {
			const ver = tag.getVersion();
			if(s.ver.empty || s.ver == ver) {
				createWorkingTree(gitDestDir, tag, s.pkg,
						opts.options.packageFolder, opts.options.libOptions);
			}
		}
	}

	return 0;
}

string getPackage(ref const(DubProxyFile) dpf, string pkg) {
	import std.path : buildPath;

	if(!dpf.pkgExists(pkg)) {
		writefln!"No package '%s' exists in DubProxyFile '%s'"(pkg,
				opts.options.proxyFile);
	}

	const string pkgPath = dpf.getPath(pkg);
	const PathKind pk = getPathKind(pkgPath);
	const gitDestDir = buildPath(opts.options.gitFolder, pkg);
	final switch(pk) {
		case PathKind.remoteGit:
			cloneBare(pkgPath, LocalGit.no, gitDestDir,
					opts.options.libOptions);
			break;
		case PathKind.localGit:
			cloneBare(pkgPath, LocalGit.yes, gitDestDir,
					opts.options.libOptions);
			break;
		case PathKind.folder:
			assert(false, "TODO");
	}
	return gitDestDir;
}

struct GetSplit {
	string pkg;
	string ver;
}

GetSplit splitGet(string str) {
	import std.string : indexOf;

	GetSplit ret;
	const colon = str.indexOf(':');
	if(colon == -1) {
		ret.pkg = str;
	} else {
		ret.pkg = str[0 .. colon];
		ret.ver = str[colon + 1 .. $];
	}
	return ret;
}

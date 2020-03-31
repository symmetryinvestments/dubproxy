import std.array : empty;
import std.stdio;
import std.getopt;
import std.experimental.logger;
import std.file : exists;
import std.path : buildPath;


import dubproxy;
import dubproxy.git;

import opts = options;

int main(string[] args) {
	auto helpInformation = opts.parseOptions(args);

	if(helpInformation.helpWanted) {
		defaultGetoptPrinter("Dubproxy is a tool to make dub work with "
			~ "private repos and to bypass code.dlang.org to fetch packages",
			helpInformation.options);
		return 0;
	}

	if(opts.options().verbose) {
		globalLogLevel(LogLevel.trace);
	} else {
		globalLogLevel(LogLevel.error);
	}

	if(opts.options.dummyDubProxy) {
		tracef("dummyDubProxy %s", opts.options.dummyDubProxyPath);
		DubProxyFile dpf;
		dpf.insertPath("dummy", "https://does_not_exist.git");
		toFile(dpf, opts.options.dummyDubProxyPath ~ "/dubproxy.json");
	}

	if(opts.options.mirrorCodeDlang) {
		tracef("mirrorCodeDlang %s", opts.options.mirrorFilename);
		DubProxyFile dpf = getCodeDlangOrgCopy();
		toFile(dpf, opts.options.mirrorFilename);
	}

	if(!opts.options.showTagsPath.empty) {
		tracef("showTags %s", opts.options.proxyFile);
		TagReturn[] tags;
		if(exists(opts.options.proxyFile)) {
			DubProxyFile dpf = fromFile(opts.options.proxyFile);
			if(dpf.pkgExists(opts.options.showTagsPath)) {
				tags = getTags(dpf.getPath(opts.options.showTagsPath),
						opts.options.tagKind, opts.options.libOptions);
			}
		} else if(exists(opts.options.showTagsPath)) {
			tags = getTags(opts.options.showTagsPath, opts.options.tagKind,
					opts.options.libOptions);
		}

		if(tags.empty) {
			writefln!"Could not find and tags for path '%s'"
				(opts.options.showTagsPath);
			return 1;
		}

		foreach(it; tags) {
			writefln("%s %s", it.hash, it.tag);
		}
		return 0;
	}

	if(opts.options.cloneAll || opts.options.cloneAllNoTerminal) {
		tracef("cloneAll proxyfile %s", opts.options.proxyFile);
		bool worked = true;
		DubProxyFile dpf = fromFile(opts.options.proxyFile);
		const len = dpf.packages.length;
		size_t i = 1;
		foreach(key, value; dpf.packages) {
			writefln!"Getting git for '%s' %d of %d"(key, i, len);
			try {
				getPackage(dpf, key);
			} catch(Exception e) {
				worked = false;
				writefln!"Update to get '%s' with msg '%s'"(key, e.toString());
			}
			++i;
		}
	}

	if(!opts.options.proxyFile.empty && opts.options.genAllTags) {
		tracef("genTags proxyFile %s, gitFolder %s", opts.options.proxyFile,
			opts.options.gitFolder);
		DubProxyFile dpf = fromFile(opts.options.proxyFile);
		tracef("_\tpackages %s", dpf.packages);
		foreach(key, value; dpf.packages) {
			try {
				tracef("_\t_\tbuild tag it %s", key);
				const gitDestDir = buildPath(opts.options.packageFolder, key);
				tracef("_\t_\tgitDestDir %s", gitDestDir);
				const GetSplit s = splitLocal(gitDestDir);
				tracef("_\t_\tsplit %s", s);
				TagReturn[] allTags = getTags(gitDestDir, TagKind.all,
						opts.options.libOptions);
				tracef("_\t_\tallTags %s", allTags);
				foreach(tag; allTags) {
					tracef("_\t_\t_\tbuild tag %s", tag);
					const ver = tag.getVersion();
					if(s.ver.empty || s.ver == ver) {
						tracef("_\t_\t_\tactually build tag split %s destdir %s"
								~ " packageFolder %s", ver, gitDestDir,
								opts.options.packageFolder);
						try {
							createWorkingTree(gitDestDir, tag, s.pkg,
									opts.options.packageFolder,
									opts.options.libOptions);
						} catch(Exception e) {
							errorf("Failed to create working tree %s",
									e.toString());
						}
					}
				}
			} catch(Exception e) {
				error(e.toString());
			}
		}
	}

	return 0;
}

string getPackage(ref const(DubProxyFile) dpf, string pkg) {
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

GetSplit splitLocal(string str) {
	import std.string : lastIndexOf;

	GetSplit ret;
	const colon = str.lastIndexOf('/');
	if(colon == -1) {
		ret.pkg = str;
	} else {
		ret.pkg = str[colon + 1 .. $];
	}
	return ret;
}

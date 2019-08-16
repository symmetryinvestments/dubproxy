import std.array : empty;
import std.stdio;
import std.getopt;
import std.file : exists;

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

	if(opts.options.dummyDubProxy) {
		DubProxyFile dpf;
		toFile(dpf, opts.options.dummyDubProxyPath ~ "/dubproxy.json");
	}

	if(opts.options.mirrorCodeDlang) {
		DubProxyFile dpf = getCodeDlangOrgCopy();
		toFile(dpf, opts.options.mirrorFilename);
	}

	if(!opts.options.showTagsPath.empty) {
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

	if(opts.options.cloneAll) {
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
		return worked == true;
	}

	if(!opts.options.packages.empty) {
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
							opts.options.packageFolder,
							opts.options.libOptions);
				}
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

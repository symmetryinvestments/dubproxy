module dubproxy.gittest;

import std.stdio;
import std.format : format;

import dubproxy;
import dubproxy.git;
import dubproxy.options;

@safe:

unittest {
	DubProxyOptions opts;
	DubProxyFile dpf = fromFile("testproxyfile.json");

	TagReturn[] tags = getTags(dpf.getPath("dubproxy"), opts);
	string h = getHashFromVersion(tags, "v0.0.1");
	assert(h == "4b9d4852c219e9eb062481f39d67118cfdd66664", h);

	h = getHashFromVersion(tags, "v0.0.2");
	assert(h == "78623dea2c9706c5622372c69e68df3b4779fb39", h);
}

unittest {
	DubProxyOptions opts;
	import std.algorithm.searching : canFind, endsWith;
	DubProxyFile dpf = fromFile("testproxyfile.json");
	TagReturn[] tags = getTags(dpf.getPath("dubproxy"), TagKind.branch, opts);
	assert(canFind!(a => a.tag.endsWith("master"))(tags),
			format("%(%s\n%)", tags));
}

unittest {
	DubProxyOptions opts;
	opts.ovrGF = OverrideGitFolder.yes;
	opts.ovrWTF = OverrideWorkTreeFolder.yes;
	DubProxyFile dpf = fromFile("testproxyfile.json");

	string xlsxPath = dpf.getPath("udt_d");
	cloneBare(xlsxPath, LocalGit.no, "CloneTmp/GitDir/udt_d", opts);
	TagReturn[] tags = getTags(xlsxPath, opts);

	foreach(tag; tags) {
		createWorkingTree("CloneTmp/GitDir/udt_d", tag, "udt_d", "CloneTmp",
				opts);
	}
}

/*
unittest {
	DubProxyOptions opts;
	opts.ovrGF = OverrideGitFolder.yes;
	opts.ovrWTF = OverrideWorkTreeFolder.yes;
	DubProxyFile dpf = fromFile("code.json");

	string xlsxPath = dpf.getPath("colored");
	cloneBare(xlsxPath, LocalGit.no, "/home/burner/.dub/GitDir/colored", opts);
	TagReturn[] tags = getTags(xlsxPath, opts);

	foreach(tag; tags) {
		createWorkingTree("/home/burner/.dub/GitDir/colored", tag, "colored",
				"/home/burner/.dub/packages", opts);
	}
}*/

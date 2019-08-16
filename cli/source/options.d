module options;

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

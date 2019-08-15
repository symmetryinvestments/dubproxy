module options;

import dubproxy.options : DubProxyOptions;

struct DubProxyCliOptions {
	DubProxyOptions libOptions;

	bool mirrorCodeDlang;
	string mirrorFilename = "code.json";
	string[] packages;
	string proxyFile = "dubproxy.json";
	string packageFolder = "~/.dub/packages/";
	string gitFolder = "~/.dub/DubProxyGits/";

	bool dummyDubProxy;
	string dummyDubProxyPath = ".";
}

private DubProxyCliOptions __options;

ref DubProxyCliOptions writeAbleOptions() {
	return __options;
}

@property ref const(DubProxyCliOptions) options() {
	return __options;
}

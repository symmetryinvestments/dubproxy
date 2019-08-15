module options;

import dubproxy.options : DubProxyOptions;

struct DubProxyCliOptions {
	DubProxyOptions libOptions;

	bool mirrorCodeDlang;
	string mirrorFilename = "code.json";
	string[] packages;
	string proxyFile;
	string packageFolder;
}

private DubProxyCliOptions __options;

ref DubProxyCliOptions writeAbleOptions() {
	return __options;
}

@property ref const(DubProxyCliOptions) options() {
	return __options;
}

module dubproxy.parsetest;

import std.stdio;

import dubproxy;

@safe:

unittest {
	DubProxyFile dpf = fromFile("testproxyfile.json");
	assert("xlsxd" in dpf.packages);
	writeln(dpf.getTags("xlsxd"));
	assert("dubproxy" in dpf.packages);
}

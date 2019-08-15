module dubproxy.parsetest;

import std.stdio;

import dubproxy;
import dubproxy.git;

@safe:

unittest {
	DubProxyFile dpf = fromFile("testproxyfile.json");
	assert("xlsxd" in dpf.packages);
	assert("dubproxy" in dpf.packages);
	assert("udt_d" in dpf.packages);
}

unittest {
	import std.file : readText;
	string d = getCodeDlangOrgData();
	DubProxyFile dpf = parseCodeDlangOrgData(d);
	toFile(dpf, "code.json");
}

module dubproxy.gittest;

import dubproxy;
import dubproxy.git;

@safe:

unittest {
	DubProxyFile dpf = fromFile("testproxyfile.json");

	TagReturn[] tags = getTags(dpf.getPath("dubproxy"));
	string h = getHashFromVersion(tags, "v0.0.1");
	assert(h == "fc7788b002b468b9f4af1d5dccd94b02712147d1", h);
}

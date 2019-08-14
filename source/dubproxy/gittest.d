module dubproxy.gittest;

import dubproxy;
import dubproxy.git;

@safe:

unittest {
	DubProxyFile dpf = fromFile("testproxyfile.json");

	TagReturn[] tags = getTags(dpf.getPath("dubproxy"));
	string h = getHashFromVersion(tags, "v0.0.1");
	assert(h == "4b9d4852c219e9eb062481f39d67118cfdd66664", h);
}

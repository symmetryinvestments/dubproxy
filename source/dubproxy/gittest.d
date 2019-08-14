module dubproxy.gittest;

import dubproxy;
import dubproxy.git;

@safe:

unittest {
	DubProxyFile dpf = fromFile("testproxyfile.json");

	TagReturn[] tags = getTags(dpf.getPath("dubproxy"));
	string h = getHashFromVersion(tags, "v0.0.1");
	assert(h == "4b9d4852c219e9eb062481f39d67118cfdd66664", h);

	h = getHashFromVersion(tags, "v0.0.2");
	assert(h == "78623dea2c9706c5622372c69e68df3b4779fb39", h);
}

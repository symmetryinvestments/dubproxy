module dubproxy.options;

import std.typecons : Flag;

alias OverrideGitFolder = Flag!"OverrideGitFolder";
alias OverrideWorkTreeFolder = Flag!"OverrideWorkTreeFolder";

struct DubProxyOptions {
	OverrideGitFolder ovrGF;
	OverrideWorkTreeFolder ovrWTF;
	string pathToGit = "git";
	string pathToDub = "dub";
	bool noUserInteraction;
}

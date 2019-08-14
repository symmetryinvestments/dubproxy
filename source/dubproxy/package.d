module dubproxy;

import std.typecons : nullable, Nullable;
import std.json;
import std.format : format;
import std.file : exists, readText;
import std.exception : enforce;
import std.stdio;

@safe:

struct DubProxyFile {
	string[string] packages;
	string pathToGit;

	string getPath(string pkg) const {
		const string* pkgPath = pkg in this.packages;
		enforce(pkgPath, format!"No package with name '%s' found in DPF"(pkg));
		return *pkgPath;
	}

	bool pkgExists(string pkg) const {
		return (pkg in this.packages) !is null;
	}

	void insertPath(string pkg, string path) {
		const(string)* oldPath = pkg in this.packages;
		enforce(oldPath is null, format!"Package '%s' already with path '%s'"(
					pkg, *oldPath));
		this.packages[pkg] = path;
	}

	void removePackage(string pkg) {
		enforce(this.pkgExists(pkg), format!"Package '%s' does not exist in DPF"(
				pkg));
		this.packages.remove(pkg);
	}
}

DubProxyFile fromFile(string path) @safe {
	enforce(exists(path), format!"No DPF exists with path '%s'"( path));
	return fromString(readText(path));
}

DubProxyFile fromString(string jsonText) @safe {
		JSONValue j = parseJSON(jsonText);

		enforce(j.type == JSONType.object, "Parsed DPF top level is "
				~ "not an object");

		const(JSONValue)* pkg = "packages" in j;
		enforce(pkg !is null, "Key 'packages does not exist in parsed DPF");
		enforce(pkg.type == JSONType.object,
				"Value of 'packages' must be object");

		DubProxyFile ret;

		JSONValue pkgCopy = *pkg;

		() @trusted {
			foreach(string key, ref JSONValue value; pkgCopy) {
				enforce(value.type == JSONType.string, format!
						("Value type to key '%s' was '%s', type string "
						 ~ "was expected")(key, value.type));
				ret.packages[key] = value.str();
			}
		}();

		auto gitPath = "gitPath" in j;
		if(gitPath) {
			enforce(gitPath.type == JSONType.string, format!
					"The gitPath must be of type string not '%s'"(gitPath.type));
			ret.pathToGit = gitPath.str();
		}

		return ret;
}

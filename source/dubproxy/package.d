module dubproxy;

import std.array : empty;
import std.typecons : nullable, Nullable;
import std.json;
import std.format : format, formattedWrite;
import std.file : exists, readText;
import std.exception : enforce;
import std.stdio;

@safe:

struct DubProxyFile {
	string[string] packages;

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
		enforce(oldPath is null, format!"Package '%s' already with path '%s'"
				(pkg, *oldPath));
		this.packages[pkg] = path;
	}

	void updatePath(string pkg, string path) {
		enforce(this.pkgExists(pkg), format!"Package '%s' must exist for update"
				(pkg));
		this.packages[pkg] = path;
	}

	void removePackage(string pkg) {
		enforce(this.pkgExists(pkg), format!"Package '%s' does not exist in DPF"
				(pkg));
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

	return ret;
}

void toFile(const(DubProxyFile) dpf, string path) {
	auto f = File(path, "w");
	toImpl(f.lockingTextWriter(), dpf);
}

string toString(const(DubProxyFile) dpf, string path) {
	import std.array : appender;
	auto app = appender!string();
	toImpl(app, dpf);
	return app.data;
}

private void toImpl(LTW)(auto ref LTW ltw, const(DubProxyFile) dpf) {
	import std.algorithm.iteration : map, joiner;
	import std.algorithm.mutation : copy;

	formattedWrite(ltw, "{\n\t\"packages\" : {\n");
	dpf.packages.byKeyValue()
		.map!(it => format!"\t\t\"%s\" : \"%s\""(it.key, it.value))
		.joiner(",\n")
		.copy(ltw);
	formattedWrite(ltw, "\n\t}");
	formattedWrite(ltw, "\n}");
}

DubProxyFile getCodeDlangOrgCopy() {
	return parseCodeDlangOrgData(getCodeDlangOrgData());
}

string getCodeDlangOrgData() @trusted {
	import std.exception : assumeUnique;
	import std.net.curl;
	import std.zlib;

	auto data = get("https://code.dlang.org/api/packages/dump");

	auto uc = new UnCompress();

	const(void[]) un = uc.uncompress(data);
	return assumeUnique(cast(const(char)[])un);
}

DubProxyFile parseCodeDlangOrgData(string data) {
	string fixUpKind(string kind) {
		switch(kind) {
			case "github": return "github.com";
			case "bitbucket": return "bitbucket.org";
			case "gitlab": return "gitlab.com";
			default:
				assert(false, kind);
		}
	}

	JSONValue parsed = parseJSON(data);
	DubProxyFile ret;

	enforce(parsed.type == JSONType.array,
			"Downloaded code.dlang.org dump was not an array");

	foreach(it; parsed.arrayNoRef()) {
		enforce(it.type == JSONType.object,
				format!"Expected object got '%s' from '%s'"(it.type,
					it.toPrettyString()));
		auto name = "name" in it;
		enforce(name && name.type == JSONType.string,
				format!"no name found in '%s'"(it.toPrettyString()));
		string nameStr = name.str;
		//write(nameStr, " : ");
		auto repo = "repository" in it;
		if(repo && repo.type == JSONType.object) {
			auto kind = "kind" in (*repo);
			auto owner = "owner" in (*repo);
			auto project = "project" in (*repo);

			enforce(kind && kind.type == JSONType.string,
					format!"kind was null in '%s'" (repo.toPrettyString()));
			enforce(owner && owner.type == JSONType.string,
					format!"owner was null in '%s'" (repo.toPrettyString()));
			enforce(project && project.type == JSONType.string,
					format!"project was null in '%s'" (repo.toPrettyString()));

			string url = format!"https://%s/%s/%s.git"(fixUpKind(kind.str),
					owner.str, project.str);
			//writeln(url);
			ret.insertPath(nameStr, url);
		}
	}

	return ret;
}

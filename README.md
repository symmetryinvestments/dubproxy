# dubproxy

[![Build Status](https://travis-ci.org/symmetryinvestments/dubproxy.svg?branch=master)](https://travis-ci.org/symmetryinvestments/dubproxy)
dubproxy is a library and cli to allow use of private dub packages and mirror
code.dlang.org, without a private registry.
It is a standalone library/cli and is completely transparent for dub.

## private libraries

Sometimes a dub project needs access to private library.
Subpackages are one solution, but getting dub to correctly work with subpackages
is not always easy.
Therefor, it is sometimes desirable to complete split out subpackages into there
own dub project.
Dubproxy allows to do that.
One of dubproxy's features is to take local/remote dub projects, located in a
git, and insert them into ~/.dub/packages such that dub thinks its just another
package from code.dlang.org.

## code.dlang.org mirroring

Code.dlang.org is not always accessible, but a still might be required right
now.
Maybe you are on a flight to dconf or code.dlang.org is down.
Dubproxy allows you to get a storable list of all packages and upstream urls.
This list can then be used by dubproxy to get a particular package or
package-version.
You need internet access of course.
As time of writing this Aug. 2019 all gits of all package of code.dlang.org
require about 6.5 GB of space.

## Examples

1. Get dubproxy(cli)
```sh
$ dub fetch dubproxy
$ dub build --config=cli
```

2. put dubproxy in your path or use `$ dub run dubproxy --`
3. get list of code.dlang.org packages
```sh
$ dubproxy -m -n codedlangorg.json
```

4. get a package from a dubproxyfile
```sh
$ dubproxy -i codedlangorg.json -g xlsxd
```
By default dubproxy will try to place the git in system default dub directory.

5. get a package and place the git a user specified directory
```sh
$ dubproxy -i codeldangorg.json -g xlsxreader -f GitCloneFolder
$ dubproxy -i codeldangorg.json -g xlsxreader:v0.6.1 -f GitCloneFolder
```

6. place the dub package in a user specified directory
```sh
$ dubproxy -i codeldangorg.json -g graphqld -o SomePackageFolder
```

7. get multiple packages
```sh
$ dubproxy -i codeldangorg.json -g graphqld -g inifiled
```

8. get all packages in a file (run before long flight)
```sh
$ dubproxy -i codeldangorg.json -a -u
```

The `-u` is necessary to disable user interaction, because some listed packages
on code.dlang.org do not exist anymore and github.com therefore askeds for a
username password combination.

9. dub is not in your path
```sh
$ dubproxy -d path_to_dub
```

10. git is not in your path
```sh
$ dubproxy -p path_to_git
```

11. generate a dummy dubproxy.json file with filename myPrivateProjects.json
```sh
$ dubproxy --dummy --dummyPath myPrivateProjects.json
```

12. get help
```sh
$ dubproxy -h
```

About Kaleidic Associates
-------------------------
We are a boutique consultancy that advises a small number of hedge fund clients.
We are not accepting new clients currently, but if you are interested in working
either remotely or locally in London or Hong Kong, and if you are a talented
hacker with a moral compass who aspires to excellence then feel free to drop me
a line: laeeth at kaleidic.io

We work with our partner Symmetry Investments, and some background on the firm
can be found here:

http://symmetryinvestments.com/about-us/

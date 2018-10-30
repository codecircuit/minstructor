# This is a temporary todo list

There are a couple of things to discuss with Christoph for this feature branch.
This list will be removed as soon as possible.

* Update docu ( copy of files to /usr/local/bin ... )
* require 'fileutils' is a new dependency
* consider gems?

Example spack package could look like that with gems

```python
    extends('ruby')

    def install(self, spec, prefix):
        gem('install', 'minstructor-{0}.gem'.format(self.version))
```

## Change log?

* Updated Rakefile according to
  https://ruby.github.io/rake/doc/rakefile_rdoc.html . Now it is possible to
  provide a custom path.


## New usage

```bash
rake install               # as before - just copy the files to /usr/local/bin
rake "install[my_bin_dir]" # install files to my_bin_dir
rake "install[my_bin_dir,my_man_dir]"
# install files to my_bin_dir and my_man_dir respectively
```

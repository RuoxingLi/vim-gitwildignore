How to handle negations?
---

`git ls-files -o -i --exclude-standard "<git root>"` will get you all the
ignored files explicitly. We could use that to handle the negated ignores (by
plugging that output into `wildignore` rather than the wildcards). The downside
to that solution is how horribly inefficient it seems, to explicitly name the
ignored files (individually) as opposed to using wildcards.

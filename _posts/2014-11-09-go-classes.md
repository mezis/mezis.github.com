---
layout: post
published: true
title: Managing complexity in Go
summary: |
  The standard build mechanics of Go can be surprising to developers coming from
  other languages, sparking numerous questions like _[What is the standard way to
  organize a Go project during
  development?](http://stackoverflow.com/questions/9985559)_

  It turns out Go packages can feel really similar to classes in object-oriented
  languages.
  <br/>
  Read on for details.

---

The gist of the answer is:

- Go is opinionated. Anything but the "standard" way will be painful.
- All the source files for a Go package should reside in the same directory.
- The source for package `github.com/dr_evil/laser` should be in
  `$GOPATH/src/github.com/dr_evil/laser`

It took me a while to wrap my head around it, but it turns out most of the
misunderstanding stems from this: for people coming from object-oriented
languages, and as far as can understand,

> Go packages are the closest construct to a class in other languages.

To be precise, `interface`s exposed by a package are. On one hand, packages provide
**isolation** and **abstraction** like any good class should. On the other, they
can't be organised into isolated units of code like an application, Ruby Gem or
Python Egg can.

It doesn't necessarily seem to make sense to have one class per package; in
practice I find myself creating a package per "tree of classes" (or rather, bags
of `struct`s sharing a common interface. So far I'm trying to keep my packages
under 1,000 LOC.

In practice, it seems to be commonplace to

- have many packages per project (these can live in the same repository);
- nest package directories inside package directories as needed;
- expose just an `interface` and a `New` function returning that interface from
  a package, if possible.

For instance, in my current side project `klask`, I'm busy building a query
parser and runner (in the context of a search engine).

The file structure looks like this:

    $GOPATH/src/github.com/mezis/klask
    |_ server.go
    |_ ...
    \_ query
       |_ query.go
       |_ ...
       |_ query_and.go
       \_ query_or.go

`server.go` at the top-level exports the `main` package and runs the
application. The `main` package imports the `github.com/mezis/klask/query`
package (indirectly). Running `go build` in the top-level project directory
creates the `klask` executable.

Now, the files under `query` all export the `query` package. `query.go` contains
all the "public" identifiers, which are just an interface:

```go
type Query interface {
  json.Unmarshaler

  // Parameters:
  // - `records` is a Redis key, containing subset of all
  //   records IDs.
  // - `context` should be `nil`.
  // Returns:
  //   a Redis key which contains a subset of the
  //   contents of `records`.
  Run(records string) (string, error)
}
```

and factory function (analogous to a constructor), where `idx` is a handle to a
database:

```go
func New(idx index.Index) (Query, error) { ... }
```

I place all internals (non-exposed identifiers) in other files, in particular
the various concretions ("subclasses") of the `Query` interface ("virtual public
class").

All implementations of the `Query` interface in the module (e.g. `query_and_t`,
`query_or_t`) satisfy `json.Unmarshaler`, which makes this interface sufficient
to parse and run queries.

If you reason on this as:

- the `query` package exposes a `Query` superclass;
- `Query` has 1 public methods, `Run`;
- `Query` inherits from `json.Unmarshaler`;
- internally, ther eare multiple `query_*_t` subclasses.

you're almost back to the comfort and safety of your usual object-oriented
paradigm.

I hope I don't get flak for this—it may well not be an idiomatic way to think
about a Go program, but it's an approximation that makes sense to me and helps
me structure a project.

Also, hopefully this will help other newbie Gophers save some time!


.onLoad <- function(libname, pkgname) {
  s3_register_vctrs()
  invisible()
}

# vctrs methods, registered only when vctrs is loaded, so that zuid vectors
# combine in tibbles and vctrs::vec_c() without vctrs being a dependency.
# vctrs double-dispatches on the first class of each argument, so each
# format registers its own pair.
s3_register_vctrs <- function() {
  register <- function(...) {
    for (format in known_formats()) {
      cls <- paste0("zuid_", format)
      vctrs_method("vec_ptype2", paste0(cls, ".", cls), vec_ptype2_zuid)
      vctrs_method("vec_cast", paste0(cls, ".", cls), vec_cast_zuid)
      vctrs_method("vec_ptype2", paste0(cls, ".character"), vec_ptype2_to_chr)
      vctrs_method("vec_ptype2", paste0("character.", cls), vec_ptype2_to_chr)
      vctrs_method("vec_cast", paste0("character.", cls), vec_cast_to_chr)
      vctrs_method("vec_cast", paste0(cls, ".character"), vec_cast_from_chr)
      vctrs_method("vec_ptype_abbr", cls, vec_ptype_abbr_zuid)
    }
  }
  if (isNamespaceLoaded("vctrs")) {
    register()
  }
  setHook(packageEvent("vctrs", "onLoad"), register)
}

vctrs_method <- function(generic, class, fun) {
  registerS3method(generic, class, fun, envir = asNamespace("vctrs"))
}

vec_ptype2_zuid <- function(x, y, ...) {
  if (!identical(zuid_format_of(x), zuid_format_of(y))) {
    zuid_abort("type", "Can't combine zuid vectors of different formats.")
  }
  if (
    !identical(attr(x, "layout", exact = TRUE), attr(y, "layout", exact = TRUE))
  ) {
    zuid_abort("layout", "Can't combine zuid vectors with different layouts.")
  }
  x[0L]
}

vec_cast_zuid <- function(x, to, ...) {
  x
}

vec_ptype2_to_chr <- function(x, y, ...) {
  character()
}

vec_cast_to_chr <- function(x, to, ...) {
  as.character(x)
}

vec_cast_from_chr <- function(x, to, ...) {
  parse_like(x, to)
}

vec_ptype_abbr_zuid <- function(x, ...) {
  zuid_format_of(x)
}

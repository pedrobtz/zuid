# TypeID's spec/valid.yml and spec/invalid.yml (tools/fixture-sources.yaml)
# as data frames. A small reader for their flat list of mappings, since zuid
# has no YAML dependency. The files are Apache-2.0, so .Rbuildignore keeps
# them out of the package tarball and the tests that read them skip there.
typeid_fixture <- function(name) {
  testthat::skip_on_cran()
  path <- test_path("fixtures", "typeid", name)
  testthat::skip_if_not(file.exists(path), "TypeID fixtures are not built")
  lines <- readLines(path, encoding = "UTF-8")
  lines <- lines[!grepl("^\\s*(#|$)", lines)]
  starts <- grep("^- ", lines)
  ends <- c(starts[-1L] - 1L, length(lines))
  rows <- Map(
    function(a, b) {
      kv <- sub("^(- )?\\s*", "", trimws(lines[a:b], "right"))
      key <- sub(":.*$", "", kv)
      value <- sub('^[^:]+:\\s*"?(.*?)"?$', "\\1", kv, perl = TRUE)
      stats::setNames(as.list(value), key)
    },
    starts,
    ends
  )
  keys <- unique(unlist(lapply(rows, names)))
  out <- lapply(keys, function(k) {
    vapply(rows, function(r) if (is.null(r[[k]])) NA_character_ else r[[k]], "")
  })
  stats::setNames(as.data.frame(out, stringsAsFactors = FALSE), keys)
}

upid_fixture <- function() {
  utils::read.csv(
    test_path("fixtures", "upid.csv"),
    colClasses = c("character", "character", "character", "numeric")
  )
}

scru128_fixture <- function() {
  utils::read.csv(
    test_path("fixtures", "scru128.csv"),
    colClasses = c("character", "character", rep("numeric", 4))
  )
}

scru64_fixture <- function() {
  utils::read.csv(
    test_path("fixtures", "scru64.csv"),
    colClasses = c("character", "character", "numeric", "numeric")
  )
}

sqids_fixture <- function() {
  utils::read.csv(
    test_path("fixtures", "sqids.csv"),
    colClasses = c("character", "integer", "character", "character"),
    na.strings = "NA"
  )
}

cid_fixture <- function() {
  utils::read.csv(
    test_path("fixtures", "cid.csv"),
    colClasses = c("character", "integer", rep("character", 4))
  )
}

# The numbers of Sqids, as a plain list.
sqids_numbers <- function(x) unclass(id_fields(x)$numbers)

#' Describe this build of zuid
#'
#' Reports the installed version, the generated tables compiled into it,
#' the entropy source and the monotonic generation state.
#'
#' @return A list with elements:
#'   \describe{
#'     \item{`version`}{the package version, as a `package_version`.}
#'     \item{`tables`}{a data frame with one row per generated table: its
#'       name, the upstream `repo`, `commit` and `path`, the file's `sha256`,
#'       and the number of `entries`.}
#'     \item{`entropy`}{the operating-system entropy source compiled in:
#'       `"getrandom"`, `"getentropy"`, `"BCryptGenRandom"` or
#'       `"arc4random_buf"`.}
#'     \item{`state`}{the session's monotonic generation state: the last
#'       version 7 millisecond and counter, the last version 1 and 6 tick
#'       and clock sequence, and the last ULID millisecond, `NA` before the
#'       first value.}
#'   }
#'
#' @examples
#' zuid_info()
#'
#' @export
zuid_info <- function() {
  state <- .Call(zuid_c_state)
  list(
    version = package_version(unname(getNamespaceVersion("zuid"))),
    tables = table_sources,
    entropy = state$entropy,
    state = state[-1L]
  )
}

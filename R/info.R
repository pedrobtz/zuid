#' Describe this build of zuid
#'
#' Reports the installed version and the generated tables compiled into it,
#' with the upstream source each was taken from.
#'
#' @return A list with elements:
#'   \describe{
#'     \item{`version`}{the package version, as a `package_version`.}
#'     \item{`tables`}{a data frame with one row per generated table: its
#'       name, the upstream `repo`, `commit` and `path`, the file's `sha256`,
#'       and the number of `entries`.}
#'   }
#'
#' @examples
#' zuid_info()
#'
#' @export
zuid_info <- function() {
  list(
    version = package_version(unname(getNamespaceVersion("zuid"))),
    tables = table_sources
  )
}

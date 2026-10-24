# Symbol-audit helpers, after zucrypt's. In a helper rather than test-abi.R so
# that testthat's parallel workers see them too.

zuid_dll_path <- function() {
  dll <- getLoadedDLLs()[["zuid"]]
  skip_if(is.null(dll), "zuid DLL is not loaded")
  path <- dll[["path"]]
  skip_if(!file.exists(path), "zuid shared object not found on disk")
  path
}

# What the shared object exports, as nm reports it. ELF needs `nm -D`
# (.dynsym); plain `nm` would list hidden symbols too. Mach-O has no separate
# dynamic table, so `nm -gU`. Windows is skipped: a DLL exports only what its
# export table names.
exported_symbols <- function() {
  nm <- Sys.which("nm")
  skip_if(!nzchar(nm), "nm is not available on this platform")
  skip_on_os("windows")
  path <- zuid_dll_path()
  args <- if (Sys.info()[["sysname"]] == "Darwin") {
    c("-gU", shQuote(path))
  } else {
    c("-D", "--defined-only", shQuote(path))
  }
  syms <- suppressWarnings(system2(nm, args, stdout = TRUE, stderr = FALSE))
  skip_if(!is.character(syms) || length(syms) == 0L, "nm produced no output")
  syms
}

# A coverage or sanitizer runtime exports symbols of its own, so the exact
# export set is only meaningful on an uninstrumented build.
is_instrumented_build <- function() {
  if (identical(Sys.getenv("R_COVR"), "true")) {
    return(TRUE)
  }
  nm <- Sys.which("nm")
  dll <- getLoadedDLLs()[["zuid"]]
  if (!nzchar(nm) || is.null(dll) || !file.exists(dll[["path"]])) {
    return(FALSE)
  }
  args <- if (Sys.info()[["sysname"]] == "Darwin") "-g" else "-D"
  syms <- suppressWarnings(
    system2(nm, c(args, shQuote(dll[["path"]])), stdout = TRUE, stderr = FALSE)
  )
  any(grepl("gcov|__llvm_prof|__asan_|__ubsan_|__tsan_|__msan_", syms))
}

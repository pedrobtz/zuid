test_that("the shared object exports nothing but R_init_zuid", {
  skip_if(
    is_instrumented_build(),
    "instrumented build: the runtime exports symbols of its own"
  )
  names <- sub("^.*[[:space:]]", "", exported_symbols())
  # musl's linker exports the toolchain's _init and _fini stubs.
  names <- setdiff(names, c("_init", "_fini"))
  names <- sub("^_", "", names)
  expect_identical(sort(names), "R_init_zuid")
})

test_that("no internal zuid_ symbol is exported", {
  syms <- exported_symbols()
  expect_length(grep("zuid_", syms, fixed = TRUE, value = TRUE), 0L)
})

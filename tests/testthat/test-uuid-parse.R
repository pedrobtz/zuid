test_that("every RFC 9562 example parses at strict to its lowercase text", {
  v <- rfc9562_vectors()
  x <- id_parse(v$text, "uuid", level = "strict")
  expect_s3_class(x, c("zuid_uuid", "zuid"))
  expect_identical(attr(x, "format"), "uuid")
  expect_identical(as.character(x), tolower(v$text))
  expect_identical(id_version(x), v$version)
})

test_that("every hex form parses to the same canonical text", {
  canonical <- "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"
  forms <- c(
    hex = canonical,
    uppercase = toupper(canonical),
    compact = gsub("-", "", canonical),
    urn = paste0("URN:uuid:", canonical),
    braced = paste0("{", canonical, "}")
  )
  for (form in names(forms)) {
    expect_identical(
      as.character(id_parse(forms[[form]], "uuid", form = form)),
      canonical,
      info = form
    )
  }
  expect_identical(
    as.character(id_parse(toupper(canonical), "uuid")),
    canonical
  )
})

test_that("syntax rejects each rule's violation", {
  bad <- c(
    short = "017f22e2-79b0-7cc3-98c4-dc0c0c07398",
    long = "017f22e2-79b0-7cc3-98c4-dc0c0c07398ff",
    hyphen = "017f22e2+79b0-7cc3-98c4-dc0c0c07398f",
    moved_hyphen = "017f22e-279b0-7cc3-98c4-dc0c0c07398f",
    alphabet = "017f22e2-79b0-7cc3-98c4-dc0c0c07398g",
    non_ascii = "017f22e2-79b0-7cc3-98c4-dc0c0c07398é",
    empty = ""
  )
  expect_identical(
    unname(id_valid(bad, "uuid", level = "syntax")),
    rep(FALSE, length(bad))
  )
  expect_false(id_valid("017f22e279b07cc398c4dc0c0c07398f", "uuid"))
  expect_false(id_valid(
    "{017f22e2-79b0-7cc3-98c4-dc0c0c07398f",
    "uuid",
    form = "braced"
  ))
  expect_false(id_valid(
    "urn:uid:017f22e2-79b0-7cc3-98c4-dc0c0c07398f",
    "uuid",
    form = "urn"
  ))
})

test_that("structure requires the RFC variant, except for nil and max", {
  ncs <- "017f22e2-79b0-7cc3-08c4-dc0c0c07398f"
  microsoft <- "017f22e2-79b0-7cc3-c8c4-dc0c0c07398f"
  future <- "017f22e2-79b0-7cc3-e8c4-dc0c0c07398f"
  for (s in c(ncs, microsoft, future)) {
    expect_true(id_valid(s, "uuid", level = "syntax"))
    expect_false(id_valid(s, "uuid", level = "structure"))
  }
  expect_true(id_valid(as.character(id_nil()), "uuid", level = "strict"))
  expect_true(id_valid(as.character(id_max()), "uuid", level = "strict"))
  expect_true(is.na(id_parse(ncs, "uuid")))
  expect_identical(as.character(id_parse(ncs, "uuid", level = "syntax")), ncs)
})

test_that("strict requires a defined version and a time not in the future", {
  version_0 <- "017f22e2-79b0-0cc3-98c4-dc0c0c07398f"
  version_9 <- "017f22e2-79b0-9cc3-98c4-dc0c0c07398f"
  expect_true(id_valid(version_0, "uuid"))
  expect_false(id_valid(version_0, "uuid", level = "strict"))
  expect_false(id_valid(version_9, "uuid", level = "strict"))

  # Version 7 at the largest millisecond, 10889-08-02: structurally fine.
  far <- "ffffffff-ffff-7fff-bfff-ffffffffffff"
  expect_true(id_valid(far, "uuid"))
  expect_false(id_valid(far, "uuid", level = "strict"))
})

test_that("the strict time tolerance is the option zuid.time_tolerance", {
  ms <- floor(as.numeric(Sys.time()) * 1000) + 3600 * 1000
  chunks <- c(ms %/% 2^32, (ms %/% 2^16) %% 2^16, ms %% 2^16)
  hex <- sprintf("%04x%04x%04x", chunks[1], chunks[2], chunks[3])
  soon <- paste0(
    substr(hex, 1, 8),
    "-",
    substr(hex, 9, 12),
    "-7000-8000-000000000000"
  )
  expect_true(id_valid(soon, "uuid", level = "strict"))
  withr::local_options(zuid.time_tolerance = 60)
  expect_false(id_valid(soon, "uuid", level = "strict"))
  withr::local_options(zuid.time_tolerance = as.difftime(2, units = "hours"))
  expect_true(id_valid(soon, "uuid", level = "strict"))
  withr::local_options(zuid.time_tolerance = -1)
  expect_error(
    id_valid(soon, "uuid", level = "strict"),
    class = "zuid_type_error"
  )
})

test_that("failures are NA, never errors, unless strict = TRUE", {
  x <- c("nope", NA, "017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
  expect_no_error(out <- id_parse(x, "uuid"))
  expect_identical(is.na(out), c(TRUE, TRUE, FALSE))
  expect_identical(id_valid(x, "uuid"), c(FALSE, NA, TRUE))
  expect_error(id_parse(x, "uuid", strict = TRUE), class = "zuid_parse_error")
  cnd <- tryCatch(id_parse(x, "uuid", strict = TRUE), error = identity)
  expect_s3_class(cnd, "zuid_error")
  expect_identical(cnd$positions, 1L)
  expect_no_error(id_parse(
    c(NA, "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"),
    "uuid",
    strict = TRUE
  ))
})

test_that("names survive parsing and validation", {
  x <- c(a = "017f22e2-79b0-7cc3-98c4-dc0c0c07398f", b = "nope")
  expect_named(id_parse(x, "uuid"), c("a", "b"))
  expect_named(id_valid(x, "uuid"), c("a", "b"))
})

test_that("arguments are checked with classed errors", {
  expect_error(id_parse(1, "uuid"), class = "zuid_type_error")
  expect_error(id_parse("x"), class = "zuid_parse_error")
  expect_error(id_parse("x", "nope"), class = "zuid_type_error")
  expect_error(
    id_parse("x", "uuid", form = "base99"),
    class = "zuid_type_error"
  )
  expect_error(id_parse("x", "uuid", strict = NA), class = "zuid_type_error")
  expect_error(id_valid(1, "uuid"), class = "zuid_type_error")
})

test_that("a zuid vector reparses as itself and refuses another format", {
  x <- id_parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f", "uuid")
  expect_identical(id_parse(x), x)
  expect_identical(id_parse(x, "uuid"), x)
  expect_true(id_valid(x, "uuid"))
  expect_error(id_parse(x, "ulid"), class = "zuid_type_error")
})

test_that("text round-trips through bytes over 10^4 values", {
  withr::local_seed(20261024)
  text <- c(random_uuid_text(5000L, 4L), random_uuid_text(5000L, 7L))
  x <- id_parse(text, "uuid")
  expect_false(anyNA(x))
  expect_identical(as.character(x), text)
  expect_identical(id_from_bytes(id_bytes(x), "uuid"), x)
  expect_identical(id_parse(id_format(x, "urn"), "uuid", form = "urn"), x)
  expect_identical(
    id_parse(id_format(x, "compact"), "uuid", form = "compact"),
    x
  )
})

test_that("id_formats() describes uuid", {
  f <- id_formats()
  row <- f[f$format == "uuid", ]
  expect_identical(row$class, "structured")
  expect_identical(row$width, 128L)
  expect_identical(row$text_min, 36L)
  expect_identical(
    row$forms[[1]],
    c(
      "hex",
      "compact",
      "urn",
      "braced",
      "uppercase",
      "base32",
      "base32rfc",
      "base32hex",
      "base36",
      "base58",
      "base62",
      "base62sort",
      "base64url",
      "base64sort",
      "alphabet",
      "proquint",
      "words"
    )
  )
})

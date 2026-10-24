test_that("every form writes what the Go and Python references write", {
  f <- encoding_fixtures()
  for (form in unique(f$form)) {
    rows <- f[f$form == form, ]
    bytes <- lapply(rows$hex, hex_bytes)
    expect_identical(id_encode(bytes, form), rows$text, label = form)
  }
})

test_that("every form reads back what the references write", {
  f <- encoding_fixtures()
  for (form in unique(f$form)) {
    rows <- f[f$form == form, ]
    bytes <- lapply(rows$hex, hex_bytes)
    expect_identical(id_decode(rows$text, form), bytes, label = form)
  }
})

test_that("the IETF draft's vectors hold where zuid follows the draft", {
  # draft-davis-uuidrev-alt-uuid-encoding-methods-00, for RFC 9562's
  # example UUID. Its Crockford vector left-aligns the bits, which no Go or
  # Python library does, so zuid does not follow it (design.md section 15).
  b <- hex_bytes("f81d4fae7dec11d0a76500a0c91e6bf6")
  expect_identical(id_encode(b, "base32hex"), "V0EKVBJTTG8T19R502GCI7JBUO")
  expect_identical(id_encode(b, "base36"), tolower("EOSWZOLG3BSX0ZN8OTQ1P8OOM"))
  expect_identical(id_encode(b, "base58"), "Xe22UfxT3rxcKJEAfL5373")
  expect_identical(id_encode(b, "base62sort"), "7YBUWgZR1mKSqGyj9tVViw")
  expect_identical(id_encode(b, "base64url"), "-B1Prn3sEdCnZQCgyR5r9g")
  expect_identical(id_encode(b, "base64sort"), "y0pEfbrg3S1bOF1VmGtfxV")
})

test_that("the Niceware reference's vectors hold", {
  b <- as.raw(c(
    0,
    0,
    17,
    212,
    12,
    140,
    90,
    247,
    46,
    83,
    254,
    60,
    54,
    169,
    255,
    255
  ))
  text <- "a billet baiting glum crawl writhing deplane zyzzyva"
  expect_identical(id_encode(b, "words", sep = " "), text)
  expect_identical(
    id_decode("A billet baiting glum Crawl writhing dePlanE zyzzYvA", "words"),
    list(b)
  )
  expect_identical(id_encode(as.raw(c(0, 0)), "words"), "a")
  expect_identical(id_encode(as.raw(c(0xff, 0xff)), "words"), "zyzzyva")
  expect_identical(id_encode(raw(), "words"), "")
  expect_identical(id_decode("you love ninetales", "words"), list(NULL))
})

test_that("the Proquint paper's example holds", {
  expect_identical(
    id_encode(as.raw(c(127, 0, 0, 1)), "proquint"),
    "lusab-babad"
  )
  expect_identical(
    id_encode(as.raw(c(63, 84, 220, 193)), "proquint"),
    "gutih-tugad"
  )
  expect_identical(
    id_decode(c("LUSAB-babad", "lusab babad", "lusabbabad"), "proquint"),
    rep(list(as.raw(c(127, 0, 0, 1))), 3)
  )
  expect_identical(
    id_decode(c("lusab-baba", "lusac-babad"), "proquint"),
    list(NULL, NULL)
  )
})

test_that("every form round-trips random bytes of every length it takes", {
  withr::local_seed(20261024)
  for (form in encoding_forms()) {
    even <- form %in% c("proquint", "words")
    lens <- if (even) seq(0, 64, by = 2) else 0:64
    bytes <- lapply(lens, function(n) as.raw(sample.int(256L, n, TRUE) - 1L))
    expect_identical(
      id_decode(id_encode(bytes, form), form),
      bytes,
      label = form
    )
  }
})

test_that("a caller's alphabet round-trips and pads with its first symbol", {
  withr::local_seed(1)
  bytes <- lapply(c(0:20, 100), function(n) {
    as.raw(sample.int(256L, n, TRUE) - 1L)
  })
  for (alphabet in c(
    "01",
    "0123456789",
    "abcdefghijklmnopqrstuvwxyz",
    "!#$%&()*+,"
  )) {
    text <- id_encode(bytes, "alphabet", alphabet = alphabet)
    expect_identical(id_decode(text, "alphabet", alphabet = alphabet), bytes)
  }
  expect_identical(
    id_encode(as.raw(c(0, 1)), "alphabet", alphabet = "0123456789"),
    "00001"
  )
  # 16 bytes in a 26-letter alphabet are 28 characters (design.md 6.5).
  expect_identical(
    nchar(id_encode(
      raw(16),
      "alphabet",
      alphabet = paste(letters, collapse = "")
    )),
    28L
  )
})

test_that("the order-preserving forms sort as their bytes do", {
  withr::local_seed(42)
  bytes <- lapply(seq_len(1e4), function(i) {
    as.raw(sample.int(256L, 16L, TRUE) - 1L)
  })
  hex <- id_encode(bytes, "hex")
  by_bytes <- order(hex, method = "radix")
  for (form in c(
    "base32",
    "base32hex",
    "base36",
    "base62",
    "base62sort",
    "base64sort",
    "proquint"
  )) {
    text <- id_encode(bytes, form)
    expect_identical(order(text, method = "radix"), by_bytes, label = form)
  }
  short <- id_encode(bytes, "alphabet")
  expect_identical(order(short, method = "radix"), by_bytes)
})

test_that("decoding rejects what is not text of the form", {
  expect_identical(
    id_decode(
      c("8ZZZZZZZZZZZZZZZZZZZZZZZZZ", "7ZZZZZZZZZZZZZZZZZZZZZZZZZ"),
      "base32",
      width = 16
    ),
    list(NULL, as.raw(rep(0xff, 16)))
  )
  # Crockford's aliases are rejected, as ULID and TypeID reject them.
  expect_identical(
    id_decode(c("0I", "0L", "0O", "0U", "01"), "base32"),
    list(NULL, NULL, NULL, NULL, as.raw(1))
  )
  # Either case where the alphabet has one case.
  expect_identical(
    id_decode(
      c("7r3n7twzfc278aes80m34hwtzp", "EOSWZOLG3BSX0ZN8OTQ1P8OOM"),
      c("base32")
    ),
    list(hex_bytes("f81d4fae7dec11d0a76500a0c91e6bf6"), NULL)
  )
  expect_identical(
    id_decode("EOSWZOLG3BSX0ZN8OTQ1P8OOM", "base36"),
    list(hex_bytes("f81d4fae7dec11d0a76500a0c91e6bf6"))
  )
  # A length no byte count produces.
  expect_identical(id_decode(c("0", "000"), "base32"), list(NULL, NULL))
  expect_identical(id_decode("A", "base64url"), list(NULL))
  # Nonzero spare bits, so one text per byte string.
  expect_identical(id_decode(c("AA", "AB"), "base64url"), list(as.raw(0), NULL))
  # Base36 above the largest 16-byte value.
  expect_identical(id_decode(strrep("z", 25), "base36"), list(NULL))
  # Case matters where the alphabet has both cases.
  expect_identical(
    id_decode("7ybuwgzr1mksqgyj9tvviw", "base62", width = 16),
    list(NULL)
  )
  expect_identical(id_decode(c("0", "l", NA), "base58"), list(NULL, NULL, NULL))
  expect_identical(id_decode("", "base58"), list(raw()))
  expect_identical(
    id_decode(c("not hex", "f8-1d"), "hex"),
    list(NULL, as.raw(c(0xf8, 0x1d)))
  )
  expect_identical(id_decode("éé", "hex"), list(NULL))
})

test_that("RFC 4648 padding is accepted on input when it is exact", {
  expect_identical(
    id_decode(
      c(
        "-B1Prn3sEdCnZQCgyR5r9g==",
        "-B1Prn3sEdCnZQCgyR5r9g=",
        "-B1Prn3sEdCnZQCgyR5r9g==="
      ),
      "base64url"
    ),
    list(hex_bytes("f81d4fae7dec11d0a76500a0c91e6bf6"), NULL, NULL)
  )
  expect_identical(
    id_decode(
      c("7AOU7LT55QI5BJ3FACQMSHTL6Y======", "AE======", "AE"),
      "base32rfc"
    ),
    list(hex_bytes("f81d4fae7dec11d0a76500a0c91e6bf6"), as.raw(1), as.raw(1))
  )
  expect_identical(
    id_decode("y0pEfbrg3S1bOF1VmGtfxV==", "base64sort"),
    list(NULL)
  )
})

test_that("`width` fixes the byte count", {
  expect_identical(
    id_decode("1111111111111112", "base58", width = 16),
    list(hex_bytes("00000000000000000000000000000001"))
  )
  expect_identical(id_decode("2", "base58", width = 16), list(NULL))
  expect_identical(id_decode("2", "base58"), list(as.raw(1)))
  expect_identical(id_decode("lusab-babad", "proquint", width = 2), list(NULL))
})

test_that("bytes come as a raw vector, a list or a matrix", {
  b <- hex_bytes("f81d4fae7dec11d0a76500a0c91e6bf6")
  x <- id_parse(c(a = "f81d4fae-7dec-11d0-a765-00a0c91e6bf6", b = NA), "uuid")
  expect_identical(id_encode(b, "base58"), "Xe22UfxT3rxcKJEAfL5373")
  expect_identical(
    id_encode(list(p = b, q = NULL), "base58"),
    c(p = "Xe22UfxT3rxcKJEAfL5373", q = NA)
  )
  expect_identical(
    id_encode(id_bytes(x), "base58"),
    c("Xe22UfxT3rxcKJEAfL5373", NA)
  )
  expect_identical(
    id_decode(c(k = "Xe22UfxT3rxcKJEAfL5373"), "base58"),
    list(k = b)
  )
})

test_that("bad arguments are type errors", {
  b <- as.raw(1:4)
  expect_error(id_encode(b, "base99"), class = "zuid_type_error")
  expect_error(id_encode(b, "compact"), class = "zuid_type_error")
  expect_error(id_encode(1:4, "hex"), class = "zuid_type_error")
  expect_error(id_encode(list(1:4), "hex"), class = "zuid_type_error")
  expect_error(id_encode(as.raw(1:3), "proquint"), class = "zuid_type_error")
  expect_error(id_encode(as.raw(1:3), "words"), class = "zuid_type_error")
  expect_error(id_encode(b, "words", sep = ""), class = "zuid_type_error")
  expect_error(id_encode(b, "proquint", sep = "x"), class = "zuid_type_error")
  expect_error(
    id_encode(b, "base58", alphabet = "01"),
    class = "zuid_type_error"
  )
  expect_error(
    id_encode(b, "alphabet", alphabet = "0"),
    class = "zuid_type_error"
  )
  expect_error(
    id_encode(b, "alphabet", alphabet = "00"),
    class = "zuid_type_error"
  )
  expect_error(
    id_encode(b, "alphabet", alphabet = "a b"),
    class = "zuid_type_error"
  )
  expect_error(
    id_encode(b, "alphabet", alphabet = "éa"),
    class = "zuid_type_error"
  )
  expect_error(id_encode(raw(65537), "hex"), class = "zuid_type_error")
  expect_error(id_decode(1, "hex"), class = "zuid_type_error")
  expect_error(id_decode("00", "hex", width = -1), class = "zuid_type_error")
  expect_error(id_decode("00", "hex", width = 1.5), class = "zuid_type_error")
})

test_that("the largest input encodes and decodes", {
  withr::local_seed(7)
  b <- as.raw(sample.int(256L, 65536L, TRUE) - 1L)
  for (form in c("base62", "base32", "words")) {
    expect_identical(id_decode(id_encode(b, form), form)[[1L]], b, label = form)
  }
})

test_that("every encoding is a UUID form, in id_format() and id_parse()", {
  f <- encoding_fixtures()
  f <- f[nchar(f$hex) == 32L & f$form != "hex", ]
  for (form in unique(f$form)) {
    rows <- f[f$form == form, ]
    x <- id_from_bytes(lapply(rows$hex, hex_bytes), "uuid")
    expect_identical(id_format(x, form), rows$text, label = form)
    back <- id_parse(rows$text, "uuid", form = form, level = "syntax")
    expect_identical(as.character(back), as.character(x), label = form)
  }
  expect_true(all(
    setdiff(encoding_forms(), "hex") %in% id_formats()$forms[[1L]]
  ))
})

test_that("a UUID form must decode to exactly 16 bytes", {
  expect_identical(
    id_valid(
      c("Xe22UfxT3rxcKJEAfL5373", "Xe22UfxT3rxcKJEAfL537", "2"),
      "uuid",
      form = "base58"
    ),
    c(TRUE, FALSE, FALSE)
  )
  expect_identical(
    id_valid(
      c("7R3N7TWZFC278AES80M34HWTZP", "8R3N7TWZFC278AES80M34HWTZP"),
      "uuid",
      form = "base32"
    ),
    c(TRUE, FALSE)
  )
  expect_true(is.na(id_parse("zobit-huvov", "uuid", form = "proquint")))
})

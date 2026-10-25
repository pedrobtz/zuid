# The vectors are sqids/sqids-spec's tests (tests/*.test.ts at the commit
# in tools/fixture-sources.yaml), and the fixture is the JavaScript
# reference, sqids 0.3.0, over random numbers, alphabets and min lengths.

test_that("the specification's encoding tests hold", {
  expect_identical(as.character(id_sqids(list(c(1, 2, 3)))), "86Rf07")
  expect_identical(
    as.character(id_sqids(0:9)),
    c("bM", "Uk", "gb", "Ef", "Vq", "uw", "OI", "AX", "p6", "nJ")
  )
  expect_identical(
    as.character(id_sqids(lapply(0:9, function(i) c(0, i)))),
    c(
      "SvIz",
      "n3qa",
      "tryF",
      "eg6q",
      "rSCF",
      "sR8x",
      "uY2M",
      "74dI",
      "30WX",
      "moxr"
    )
  )
  expect_identical(
    as.character(id_sqids(lapply(0:9, function(i) c(i, 0)))),
    c(
      "SvIz",
      "nWqP",
      "tSyw",
      "eX68",
      "rxCY",
      "sV8a",
      "uf2K",
      "7Cdk",
      "3aWP",
      "m2xn"
    )
  )
  many <- list(c(0, 0, 0, 1, 2, 3, 100, 1000, 1e5, 1e6, 2^53 - 1), 0:99)
  expect_identical(sqids_numbers(id_sqids(many)), lapply(many, as.numeric))
  expect_identical(as.character(id_sqids(list(numeric()))), "")
  expect_error(id_sqids(-1), class = "zuid_type_error")
  expect_error(id_sqids(2^53), class = "zuid_encode_error")
})

test_that("the specification's min_length tests hold", {
  long <- "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTM"
  map <- c(
    `6` = "86Rf07",
    `7` = "86Rf07x",
    `8` = "86Rf07xd",
    `9` = "86Rf07xd4",
    `10` = "86Rf07xd4z",
    `11` = "86Rf07xd4zB",
    `12` = "86Rf07xd4zBm",
    `13` = "86Rf07xd4zBmi",
    `62` = long,
    `63` = paste0(long, "y"),
    `64` = paste0(long, "yf"),
    `65` = paste0(long, "yf1")
  )
  for (m in names(map)) {
    x <- id_sqids(list(c(1, 2, 3)), min_length = as.integer(m))
    expect_identical(as.character(x), map[[m]], label = m)
    y <- id_parse(map[[m]], "sqids", min_length = as.integer(m))
    expect_identical(sqids_numbers(y), list(c(1, 2, 3)), label = m)
  }
  expect_identical(
    as.character(id_sqids(list(c(0, 0)), min_length = 62)),
    "SvIzsqYMyQwI3GWgJAe17URxX8V924Co0DaTZLtFjHriEn5bPhcSkfmvOslpBu"
  )
  expect_error(id_sqids(1, min_length = 256), class = "zuid_type_error")
  expect_error(id_sqids(1, min_length = -1), class = "zuid_type_error")
})

test_that("the specification's blocklist tests hold", {
  expect_identical(as.character(id_sqids(4572721)), "JExTR")
  expect_identical(
    as.character(id_sqids(4572721, blocklist = character())),
    "aho1e"
  )
  # "aho1e" decodes, but it is not the canonical Sqid of its number.
  expect_false(id_valid("aho1e", "sqids"))
  expect_true(id_valid("aho1e", "sqids", level = "syntax"))
  expect_identical(as.character(id_sqids(1e5, blocklist = "ArUO")), "QyG4")
  expect_identical(
    as.character(id_sqids(
      list(c(1e6, 2e6)),
      blocklist = c("JSwXFaosAN", "OCjV9JK64o", "rBHf", "79SM", "7tE6")
    )),
    "1aYeB7bRUt"
  )
  expect_identical(as.character(id_sqids(100, blocklist = "hey")), "86u")
  expect_identical(as.character(id_sqids(100, blocklist = "86u")), "sec")
  expect_identical(as.character(id_sqids(1e6, blocklist = "vFo")), "gMvFo")
  four <- list(c(100, 202, 303, 404))
  expect_identical(
    as.character(id_sqids(four, blocklist = "lP3i")),
    "oDqljxrokxRt"
  )
  expect_identical(
    as.character(id_sqids(four, blocklist = "1HkYs")),
    "oDqljxrokxRt"
  )
  seven <- list(c(101, 202, 303, 404, 505, 606, 707))
  expect_identical(
    as.character(id_sqids(seven, blocklist = "0hfxX")),
    "862REt0hfxXVdsLG8vGWD"
  )
  expect_identical(
    as.character(id_sqids(seven, blocklist = "hfxX")),
    "seu8n1jO9C4KQQDxdOxsK"
  )
  x <- id_sqids(
    list(c(1, 2, 3)),
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
    blocklist = "sxnzkl"
  )
  expect_identical(as.character(x), "IBSHOZ")
  expect_error(
    id_sqids(
      list(0),
      alphabet = "abc",
      min_length = 3,
      blocklist = c("cab", "abc", "bca")
    ),
    class = "zuid_encode_error"
  )
})

test_that("the specification's alphabet tests hold", {
  x <- id_sqids(list(c(1, 2, 3)), alphabet = "0123456789abcdef")
  expect_identical(as.character(x), "489158")
  expect_identical(
    sqids_numbers(id_parse("489158", "sqids", alphabet = "0123456789abcdef")),
    list(c(1, 2, 3))
  )
  for (a in c(
    "abc",
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_+|{}[];:'\"/?.>,<`~"
  )) {
    y <- id_sqids(list(c(1, 2, 3)), alphabet = a)
    expect_identical(sqids_numbers(y), list(c(1, 2, 3)))
  }
  expect_error(id_sqids(1, alphabet = "ë1092"), class = "zuid_type_error")
  expect_error(id_sqids(1, alphabet = "aabcdefg"), class = "zuid_type_error")
  expect_error(id_sqids(1, alphabet = "ab"), class = "zuid_type_error")
})

test_that("the JavaScript reference's Sqids hold both ways", {
  f <- sqids_fixture()
  for (i in seq_len(nrow(f))) {
    numbers <- as.numeric(strsplit(f$numbers[i], " ")[[1]])
    if (is.na(f$id[i])) {
      expect_error(
        id_sqids(
          list(numbers),
          alphabet = f$alphabet[i],
          min_length = f$min_length[i]
        ),
        class = "zuid_encode_error"
      )
      next
    }
    x <- id_sqids(
      list(numbers),
      alphabet = f$alphabet[i],
      min_length = f$min_length[i]
    )
    expect_identical(as.character(x), f$id[i])
    y <- id_parse(
      f$id[i],
      "sqids",
      alphabet = f$alphabet[i],
      min_length = f$min_length[i]
    )
    expect_identical(sqids_numbers(y), list(numbers))
  }
})

test_that("the parameters travel with the vector", {
  x <- id_sqids(1:3, alphabet = "0123456789abcdef", min_length = 8)
  expect_identical(attr(x, "alphabet"), "0123456789abcdef")
  expect_identical(attr(x, "min_length"), 8L)
  x[2] <- as.character(id_sqids(
    9,
    alphabet = "0123456789abcdef",
    min_length = 8
  ))
  expect_identical(sqids_numbers(x), list(1, 9, 3))
  expect_identical(id_parse(x), x)
  expect_identical(sqids_numbers(c(x, x)), rep(list(1, 9, 3), 2))
  expect_error(c(x, id_sqids(1)), class = "zuid_type_error")
  expect_null(attr(id_sqids(1), "alphabet"))
  expect_error(id_bytes(x), class = "zuid_type_error")
  expect_identical(id_format(x), as.character(x))
  expect_error(
    id_parse("abc", "uuid", alphabet = "abc"),
    class = "zuid_type_error"
  )
  expect_error(
    id_parse("abc", "nanoid", min_length = 3),
    class = "zuid_type_error"
  )
})

test_that("id_valid() checks a zuid vector under its own parameters", {
  s <- id_sqids(c(1, 2), alphabet = "abcdefghij", min_length = 6)
  expect_identical(id_valid(s, "sqids"), c(TRUE, TRUE))
  expect_identical(
    id_valid(as.character(s), "sqids", alphabet = "abcdefghij", min_length = 6),
    c(TRUE, TRUE)
  )
  n <- id_nanoid(2, 8, alphabet = "xyz")
  expect_identical(id_valid(n, "nanoid"), c(TRUE, TRUE))
  # A vector of another format is only text.
  expect_identical(id_valid(id_nil(), "ulid"), FALSE)
})

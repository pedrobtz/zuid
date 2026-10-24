test_that("the JavaScript reference's CIDs parse to their fields", {
  # js-multiformats 13.3.1 over random digests, 17 multibases (fixture).
  f <- cid_fixture()
  x <- id_parse(f$text, "cid")
  expect_identical(as.character(x), f$text)
  fields <- id_fields(x)
  expect_identical(fields$version, f$version)
  expect_identical(fields$codec, f$codec)
  expect_identical(fields$hash, f$hash)
  expect_identical(fields$digest, f$digest)
  expect_identical(
    vapply(id_bytes(x), function(b) paste(format(b), collapse = ""), ""),
    f$bytes
  )
})

test_that("go-cid's string vectors parse", {
  # ipfs/go-cid cid_test.go.
  x <- id_parse(
    c(
      "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n",
      "bafkreie5qrjvaw64n4tjm6hbnm7fnqvcssfed4whsjqxzslbd3jwhsk3mm",
      "k2cwueckqkibutvhkr4p2ln2pjcaxaakpd9db0e7j7ax1lxhhxy3ekpv",
      "Qmf5Qzp6nGBku7CEn2UQx4mgN8TW69YUok36DrGa6NN893",
      "zb2rhZi1JR4eNc2jBGaRYJKYM8JEB4ovenym8L1CmFsRAytkz",
      "f015512209d8453505bdc6f269678e16b3e56c2a2948a41f2c792617cc9611ed363c95b63"
    ),
    "cid"
  )
  expect_false(anyNA(x))
  f <- id_fields(x)
  expect_identical(f$version, c(0L, 1L, 1L, 0L, 1L, 1L))
  expect_identical(
    f$digest[2],
    "9d8453505bdc6f269678e16b3e56c2a2948a41f2c792617cc9611ed363c95b63"
  )
  expect_identical(f$digest[6], f$digest[2])
  expect_identical(f$codec[c(1, 2)], c("dag-pb", "raw"))
  identity <- id_parse(
    "bafkqarjpmzuwyzltorxxezjpkvcfgqkfjfbfcvslivje2vchkzdu6rckjjcfgtkolaze6mssjqzeyn2ekrcfatkjku2vowseky3fswkfkm2deqkrju3e2",
    "cid"
  )
  expect_identical(id_fields(identity)$hash, "identity")
  expect_false(id_valid(
    "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zIII",
    "cid"
  ))
})

test_that("CID structure checks the version, varints and digest length", {
  # A sha2-256 digest of 31 bytes: it decodes, but fails structure.
  b <- as.raw(c(0x01, 0x55, 0x12, 0x1f, rep(0xaa, 31)))
  short <- paste0("f", paste(format(b), collapse = ""))
  expect_true(id_valid(short, "cid", level = "syntax"))
  expect_false(id_valid(short, "cid"))
  bad <- c(
    "",
    "x0155",
    "f02551220", # version 2
    "f0155122", # odd hex
    "F015512209d8453505bdc6f269678e16b3e56c2a2948a41f2c792617cc9611ed363c95b63", # case
    "f01d5" # truncated
  )
  expect_identical(
    id_valid(bad, "cid", level = "syntax"),
    rep(FALSE, length(bad))
  )
  # A non-minimal varint.
  expect_false(id_valid(
    paste0("f", "8100", "551220", strrep("00", 32)),
    "cid",
    level = "syntax"
  ))
})

test_that("CIDs round-trip through bytes", {
  f <- cid_fixture()
  x <- id_parse(f$text, "cid")
  y <- id_from_bytes(id_bytes(x), "cid")
  expect_identical(id_bytes(y), id_bytes(x))
  expect_true(all(startsWith(as.character(y)[f$version == 1], "b")))
  expect_true(all(startsWith(as.character(y)[f$version == 0], "Qm")))
  expect_error(
    id_from_bytes(list(as.raw(1:3)), "cid"),
    class = "zuid_parse_error"
  )
  expect_error(id_convert(x, "uuid"), class = "zuid_convert_error")
})

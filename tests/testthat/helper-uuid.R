# RFC 9562 Appendix A and B test vectors (design.md section 7, oracle 1).
rfc9562_vectors <- function() {
  data.frame(
    section = c("A.1", "A.2", "A.3", "A.4", "A.5", "A.6", "B.1", "B.2"),
    text = c(
      "C232AB00-9414-11EC-B3C8-9F6BDECED846",
      "5df41881-3aed-3515-88a7-2f4a814cf09e",
      "919108f7-52d1-4320-9bac-f847db4148a8",
      "2ed6657d-e927-568b-95e1-2665a8aea6a2",
      "1EC9414C-232A-6B00-B3C8-9F6BDECED846",
      "017F22E2-79B0-7CC3-98C4-DC0C0C07398F",
      "2489E9AD-2EE2-8E00-8EC9-32D5F69181C0",
      "5c146b14-3c52-8afd-938a-375d0df1fbf6"
    ),
    version = c(1L, 3L, 4L, 5L, 6L, 7L, 8L, 8L),
    stringsAsFactors = FALSE
  )
}

# 2022-02-22T14:22:22-05:00, the instant of A.1, A.5 and A.6.
rfc9562_instant <- function() {
  as.POSIXct("2022-02-22 19:22:22", tz = "UTC")
}

# n random UUID strings of the given version with the RFC variant, from a
# seeded stream; text, not zuid's generator, which is Stage 2's.
random_uuid_text <- function(n, version = 4L) {
  bytes <- matrix(as.raw(sample.int(256L, 16L * n, replace = TRUE) - 1L), 16L)
  bytes[7L, ] <- as.raw(bitwOr(
    bitwAnd(as.integer(bytes[7L, ]), 0x0fL),
    version * 16L
  ))
  bytes[9L, ] <- as.raw(bitwOr(bitwAnd(as.integer(bytes[9L, ]), 0x3fL), 0x80L))
  hex <- apply(bytes, 2L, function(b) paste(format(b), collapse = ""))
  paste(
    substr(hex, 1L, 8L),
    substr(hex, 9L, 12L),
    substr(hex, 13L, 16L),
    substr(hex, 17L, 20L),
    substr(hex, 21L, 32L),
    sep = "-"
  )
}

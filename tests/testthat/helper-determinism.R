# Every generator and encoding on fixed inputs, with their fields, as lines
# of text. design.md section 12: the same input gives byte-identical zuid
# vectors and id_fields() frames on every platform, so each CI leg compares
# this against one committed file.
determinism_lines <- function() {
  .Call(zuid:::zuid_c_reset_state)
  on.exit(.Call(zuid:::zuid_c_reset_state))
  r <- function(n) as.raw((seq_len(n) * 37L + 11L) %% 256L)
  t <- 1700000000123
  vectors <- list(
    uuid1 = id_uuid(3, 1, random = r(8), time = t),
    uuid4 = id_uuid(3, 4, random = r(48)),
    uuid6 = id_uuid(3, 6, random = r(8), time = t),
    uuid7 = id_uuid(3, 7, random = r(30), time = t),
    uuid8 = id_uuid(2, 8, random = r(32)),
    ulid = id_ulid(3, random = r(30), time = t),
    typeid = id_typeid(2, "user", random = r(20), time = t + 1),
    upid = id_upid(2, "abc", random = r(16), time = t),
    scru128 = id_scru128(3, random = r(30), time = t),
    scru64 = id_scru64(3, 7, 8, random = r(9), time = t),
    ksuid = id_ksuid(2, random = r(32), time = t),
    xid = id_xid(3, process = 4242, random = r(6), time = t),
    objectid = id_objectid(3, random = r(8), time = t),
    snowflake = id_snowflake(3, id_layout("twitter"), list(datacenter = 3, worker = 9), time = t),
    nanoid = id_nanoid(2, 21, random = r(64)),
    sqids = id_sqids(list(c(1, 2, 3), 2^53 - 1), min_length = 10),
    cid = id_parse("bafkreie5qrjvaw64n4tjm6hbnm7fnqvcssfed4whsjqxzslbd3jwhsk3mm", "cid")
  )
  lines <- character()
  for (nm in names(vectors)) {
    x <- vectors[[nm]]
    f <- id_fields(x)
    ms <- id_time(x, "ms")
    lines <- c(
      lines,
      paste(nm, as.character(x)),
      paste(nm, "time", ifelse(is.na(ms), "NA", sprintf("%.0f", ms))),
      paste(nm, "fields", f$version, f$variant, f$node, f$process, f$sequence, f$random, f$prefix, f$codec, f$hash, f$digest)
    )
  }
  bytes <- r(16)
  for (form in setdiff(encoding_forms(), "alphabet")) {
    lines <- c(lines, paste("encode", form, id_encode(bytes, form)))
  }
  lines
}

test_that("strict rejects a time past now plus the tolerance, for every format", {
  local_fresh_state()
  tw <- id_layout("twitter")
  s6 <- id_layout("scru64", node_bits = 8)
  future <- list(
    ulid = list(text = "7ZZZZZZZZZZZZZZZZZZZZZZZZZ"),
    typeid = list(
      text = as.character(id_typeid(
        1,
        "user",
        random = raw(10),
        time = 2^48 - 1
      ))
    ),
    upid = list(
      text = as.character(id_upid(1, "user", random = raw(8), time = 2^48 - 1))
    ),
    scru128 = list(
      text = as.character(id_scru128(1, random = raw(10), time = 2^48 - 2))
    ),
    scru64 = list(
      text = as.character(id_scru64(
        1,
        node = 1,
        node_bits = 8,
        random = raw(3),
        time = 282429536479 * 256
      )),
      layout = s6
    ),
    ksuid = list(text = "aWgEPTl1tmebfsQzFP4bxwgy80V"),
    xid = list(
      text = as.character(id_xid(1, random = raw(6), time = (2^32 - 1) * 1000))
    ),
    objectid = list(
      text = as.character(id_objectid(
        1,
        random = raw(8),
        time = (2^32 - 1) * 1000
      ))
    ),
    snowflake = list(
      text = as.character(id_snowflake(
        1,
        tw,
        list(datacenter = 1, worker = 1),
        time = tw$epoch + 2^41 - 1
      )),
      layout = tw
    )
  )
  for (f in names(future)) {
    v <- future[[f]]
    expect_true(
      id_valid(v$text, f, layout = v$layout, level = "structure"),
      label = f
    )
    expect_false(
      id_valid(v$text, f, layout = v$layout, level = "strict"),
      label = f
    )
  }
  # A large enough tolerance admits the KSUID maximum, in 2150.
  withr::local_options(zuid.time_tolerance = 1e10)
  expect_true(id_valid(
    "aWgEPTl1tmebfsQzFP4bxwgy80V",
    "ksuid",
    level = "strict"
  ))
})

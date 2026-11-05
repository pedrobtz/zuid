test_that("an entropy failure is a zuid_entropy_error from every generator", {
  local_fresh_state()
  before <- zuid_info()$state
  local_entropy_failure()
  calls <- list(
    uuid4 = function() uuid(2, version = 4),
    uuid7 = function() uuid(2),
    uuid1 = function() uuid(2, version = 1),
    uuid6 = function() uuid(2, version = 6),
    ulid = function() ulid(2),
    typeid = function() typeid(2, "user"),
    upid = function() upid(2, "user"),
    scru128 = function() scru128(2),
    scru64 = function() scru64(2, node = 1, node_bits = 8),
    ksuid = function() ksuid(2),
    xid = function() xid(2),
    objectid = function() objectid(2),
    nanoid = function() nanoid(2)
  )
  for (f in names(calls)) {
    expect_error(calls[[f]](), class = "zuid_entropy_error", label = f)
  }
  # Nothing was recorded in the session's state.
  expect_identical(zuid_info()$state, before)
})

test_that("generation works again once the entropy source does", {
  local_fresh_state()
  local({
    local_entropy_failure()
    expect_error(uuid(), class = "zuid_entropy_error")
  })
  expect_s3_class(uuid(), "zuid_uuid")
})

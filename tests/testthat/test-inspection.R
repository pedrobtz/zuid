test_that("inspection never raises on input, for any format (design 8)", {
  x <- c(
    NA,
    "",
    "été",
    "not an id",
    strrep("a", 5000),
    "01ARZ3NDEKTSV4RRFFQ69G5FAV",
    "175928847299117063"
  )
  layouts <- list(
    snowflake = id_layout("twitter"),
    scru64 = id_layout("scru64", node_bits = 8)
  )
  for (format in id_formats()$format) {
    layout <- layouts[[format]]
    for (level in c("syntax", "structure", "strict")) {
      expect_no_error(id_valid(x, format, layout = layout, level = level))
    }
    expect_no_error(id_detect(x, hint = format, layout = layout))
    expect_no_error(p <- id_parse(x, format, layout = layout, strict = FALSE))
    expect_no_error(id_fields(p))
    expect_no_error(id_time(p))
  }
})

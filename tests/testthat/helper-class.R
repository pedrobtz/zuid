# Three parsed UUIDs, the last missing, for the vector class tests.
uuids <- function() {
  id_parse(
    c(
      a = "017f22e2-79b0-7cc3-98c4-dc0c0c07398f",
      b = "c232ab00-9414-11ec-b3c8-9f6bdeced846",
      c = NA
    ),
    "uuid"
  )
}

# Every collision design.md section 6.2 names, as a table: the string, the
# hint and layout given, the format expected (NA when undecided) and the
# candidates.
detect_cases <- function() {
  tw <- id_layout("twitter")
  s6 <- id_layout("scru64", node_bits = 8)
  list(
    list("018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3", NULL, NULL, "uuid", "uuid"),
    list("018F6B1C-2D3E-7A4B-8C5D-6E7F8091A2B3", NULL, NULL, "uuid", "uuid"),
    # A ULID, and in lowercase also a TypeID without a prefix.
    list("01ARZ3NDEKTSV4RRFFQ69G5FAV", NULL, NULL, "ulid", "ulid"),
    list("01ARZ3NDEKTSV4rrffq69g5fav", NULL, NULL, "ulid", "ulid"),
    list("01arz3ndektsv4rrffq69g5fav", NULL, NULL, NA, c("ulid", "typeid")),
    list("01arz3ndektsv4rrffq69g5fav", "ulid", NULL, "ulid", "ulid"),
    list("01arz3ndektsv4rrffq69g5fav", "typeid", NULL, "typeid", "typeid"),
    # A UUID in Crockford base32 is textually a ULID; the ULID wins.
    list("7R3N7TWZFC278AES80M34HWTZP", NULL, NULL, "ulid", "ulid"),
    list("prefix_01h455vb4pex5vsknk084sn02q", NULL, NULL, "typeid", "typeid"),
    list("user_2accvpp5guht4dts56je5a", NULL, NULL, "upid", "upid"),
    # A UUID in base36 is textually a SCRU128; the SCRU128 wins.
    list("0372hg16csmsm50l8dikcvukc", NULL, NULL, "scru128", "scru128"),
    list("eoswzolg3bsx0zn8otq1p8oom", NULL, NULL, "scru128", "scru128"),
    # A SCRU64 is chosen only under a layout; with a hint a NanoID competes.
    list("0u2pf62ji4b9", NULL, NULL, NA, "scru64"),
    list("0u2pf62ji4b9", NULL, s6, "scru64", "scru64"),
    list("0u2pf62ji4b9", c("scru64", "nanoid"), s6, NA, c("scru64", "nanoid")),
    # A KSUID, and with a hint also a NanoID of that length.
    list("0ujtsYcgvSTl8PAuAdqWYSMnLOv", NULL, NULL, "ksuid", "ksuid"),
    list(
      "0ujtsYcgvSTl8PAuAdqWYSMnLOv",
      c("ksuid", "nanoid"),
      NULL,
      NA,
      c("ksuid", "nanoid")
    ),
    list("9m4e2mr0ui3e8a215n4g", NULL, NULL, "xid", "xid"),
    # 20 hex digits that are an XID, and as digits also a Snowflake.
    list("12345678901234567890", NULL, NULL, "xid", "xid"),
    list(
      "12345678901234567890",
      NULL,
      id_layout("discord"),
      NA,
      c("xid", "snowflake")
    ),
    list("56e1fc72e0c917e9c4714161", NULL, NULL, "objectid", "objectid"),
    # Decimal is a Snowflake only under a layout.
    list("175928847299117063", NULL, NULL, NA, character()),
    list("175928847299117063", NULL, tw, "snowflake", "snowflake"),
    list(
      "bafkreie5qrjvaw64n4tjm6hbnm7fnqvcssfed4whsjqxzslbd3jwhsk3mm",
      NULL,
      NULL,
      "cid",
      "cid"
    ),
    list(
      "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n",
      NULL,
      NULL,
      "cid",
      "cid"
    ),
    # Syntactic formats and encodings need a hint (D10).
    list("V1StGXR8_Z5jdHi6B-myT", NULL, NULL, NA, character()),
    list("V1StGXR8_Z5jdHi6B-myT", "nanoid", NULL, "nanoid", "nanoid"),
    list("tz4a98xxat96iws9zmbrgj3a", NULL, NULL, NA, character()),
    list("tz4a98xxat96iws9zmbrgj3a", "cuid2", NULL, "cuid2", "cuid2"),
    list("86Rf07", NULL, NULL, NA, character()),
    list("86Rf07", "sqids", NULL, "sqids", "sqids"),
    list("nope", NULL, NULL, NA, character())
  )
}

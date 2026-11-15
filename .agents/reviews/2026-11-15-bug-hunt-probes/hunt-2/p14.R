source("pre.R")
# Sqids: blocklist travels with vector but cannot be given to id_parse()/id_valid() for text
s <- sqids(c(4572721, 1, 2), blocklist = character())
p(as.character(s)); p(as.character(sqids(c(4572721, 1, 2))))
p(id_valid(s, "sqids")); p(id_valid(as.character(s), "sqids"))
p(id_parse(as.character(s), "sqids")); p(id_fields(s)$numbers)
p(tryCatch(id_parse(as.character(s), "sqids", blocklist=character()), error=function(e) conditionMessage(e)))
# min_length travel
s3 <- sqids(list(c(1,2,3)), min_length=10); p(as.character(s3)); p(id_valid(as.character(s3), "sqids")); p(id_valid(as.character(s3), "sqids", min_length=10)); p(id_valid(s3, "sqids")); p(id_valid(s3, "sqids", min_length=0))
p(id_parse(s3)); p(id_parse(s3, min_length=0)); p(id_parse(s3, min_length=11))
p(id_parse(as.character(s3), "sqids", min_length=255)); p(tryCatch(id_parse("a","sqids", min_length=256), error=function(e) class(e)[1])); p(tryCatch(id_parse("a","sqids", min_length=2.5), error=function(e) class(e)[1]))
p(id_parse(c("", NA, "86Rf07"), "sqids")); p(id_fields(id_parse(c("", NA, "86Rf07"), "sqids"))$numbers)
p(id_valid("", "sqids", min_length=5)); p(lengths(id_fields(id_parse("", "sqids", min_length = 5))$numbers))
# alphabet with space / regex chars
p(as.character(sqids(c(1,2,3), alphabet=" ab]^-\\")))
p(id_valid(as.character(sqids(c(1,2,3), alphabet=" ab]^-\\")), "sqids", alphabet=" ab]^-\\"))
# 2^53 boundary
big <- sqids(list(2^53-1)); p(as.character(big)); p(id_fields(big)$numbers[[1]] == 2^53-1)
# nanoid
p(id_valid(c("V1StGXR8_Z5jdHi6B-myT", "", "a b", "a.b", "abc"), "nanoid"))
p(id_valid(c("a.b", "a]b", "a^b", "a-b", "a\\b", ""), "nanoid", alphabet="ab.]^\\"))
n <- nanoid(3, alphabet="abc"); p(id_valid(n, "nanoid")); p(id_valid(as.character(n), "nanoid", alphabet="xyz")); p(id_valid(n, "nanoid", alphabet="xyz")); p(id_valid(n, "uuid"))
p(id_parse(n)); p(tryCatch(id_parse(n, "uuid"), error=function(e) class(e)[1]))
p(id_valid(strrep("a", 70000), "nanoid")); p(id_valid(strrep("a", 33), "cuid2"))
# id_parse on zuid with other level
u <- id_parse("018f6b1c-2d3e-7a4b-0c5d-6e7f8091a2b3", "uuid", level="syntax"); p(u); p(id_parse(u)); p(id_valid(u, "uuid")); p(id_fields(u)[,c("version","variant")])
p(id_format(u, "urn")); p(id_bytes(u)[,1])

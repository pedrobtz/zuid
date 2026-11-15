source("pre.R")
p(id_valid(c("ABARpJzdz9", "E7ozTuglZhB", "U6K52tHyjGzD"), "sqids", level="syntax"))
p(id_valid(c("ABARpJzdz9", "E7ozTuglZhB", "U6K52tHyjGzD"), "sqids"))
# typeid strict vs its uuid
t <- "a_7zzzzzzzzzfzzgzzzzzzzzzzzz"
x <- id_parse(t, "typeid")
p(id_valid(t, "typeid", level="strict")); p(id_valid(as.character(id_convert(x, "uuid")), "uuid", level="strict")); p(as.character(id_convert(x, "uuid")))
p(id_version(x)); p(id_time(x))

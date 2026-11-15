source("hdr.R")
x <- unclass(uuid(3.3e7)); attributes(x) <- NULL
bad <- which(x[-1] <= x[-length(x)])
cat("default tolerance, uuid(3.3e7): positions not above predecessor:", length(bad), " first:", bad[1] + 1, "\n")
print(x[bad[1] + (-1:2)])

source("pre.R")
options(digits.secs=6, digits=17)
tm <- as.POSIXct("2024-03-05 12:34:56.789", tz="UTC"); ms <- 1709642096789
r <- function(k) as.raw((seq_len(k) * 37) %% 256)
chk <- function(label, f) { a <- t(f()); st <- zuid_info()$state; b <- t(f()); cat("##", label, " pure:", identical(a,b), "\n") ; invisible(a)}
for (v in c(4,7,8)) chk(paste("uuid", v), function() uuid(3, v, random = r(if (v==7) 30 else 48), time = tm))
chk("uuid1", function() uuid(3, 1, random = r(8), time = tm))
chk("uuid6 node", function() uuid(3, 6, random = r(2), node=as.raw(1:6), time = tm))
chk("ulid", function() ulid(3, random=r(30), time=tm))
chk("typeid", function() typeid(3, "ab_c", random=r(30), time=tm))
chk("upid", function() upid(3, "ab", random=r(24), time=tm))
chk("scru128", function() scru128(3, random=r(30), time=tm))
chk("scru64", function() scru64(3, 5, 8, random=r(9), time=tm))
chk("ksuid", function() ksuid(3, random=r(48), time=tm))
chk("xid", function() xid(3, random=r(6), time=tm))
chk("objectid", function() objectid(3, random=r(8), time=tm))
chk("nanoid", function() nanoid(3, random=r(200)))
# time round trip
gens <- list(uuid7=function(t) uuid(2,7,time=t), uuid1=function(t) uuid(2,1,time=t), uuid6=function(t) uuid(2,6,time=t),
  ulid=function(t) ulid(2,time=t), typeid=function(t) typeid(2,"a",time=t), upid=function(t) upid(2,"a",time=t),
  scru128=function(t) scru128(2,time=t, rollback="reset"), scru64=function(t) scru64(2,1,8,time=t, rollback="reset"), ksuid=function(t) ksuid(2,time=t),
  xid=function(t) xid(2,time=t), objectid=function(t) objectid(2,time=t))
for (g in names(gens)) for (tt in list(tm, ms, 1709642096789.6, 1709642096L*1000, c(ms, ms+5000))) {
  x <- t(gens[[g]](tt)); if (inherits(x,"err")) next
  cat(g, class(tt)[1], sprintf("%.3f", id_time(x, "ms")), format(id_time(x)[1]), " f$time==id_time:", identical(id_fields(x)$time, unname(id_time(x))), "\n")
}
# bounds
p("uuid7 max", id_time(uuid(1,7,time=2^48-1),"ms")); p("uuid7 over", uuid(1,7,time=2^48)); p("uuid7 neg", uuid(1,7,time=-1)); p("uuid7 0", id_time(uuid(1,7,time=0),"ms"))
p("uuid1 min", {x <- uuid(1,1,time=-12219292800000); print(x); id_time(x,"ms")})
p("uuid1 below", uuid(1,1,time=-12219292800001))
p("uuid1 max", {x <- uuid(1,1,time=103072857660684.688); print(x); id_time(x,"ms")})
p("uuid6 max", {x <- uuid(1,6,time=103072857660684.688); print(x); id_time(x,"ms")})
p("ulid max", {x <- ulid(1,time=2^48-1); print(x); id_time(x,"ms")})
p("ulid max n=2", ulid(2,time=2^48-1))
p("uuid7 max n=5000", {x <- uuid(5000,7,time=2^48-1); range(id_time(x,"ms"))})
p("upid max", {x <- upid(1,"a",time=2^48-1); print(x); id_time(x,"ms")})
p("scru128 0", scru128(1,time=0)); p("scru128 max", {x<-scru128(1,time=2^48-2, rollback="reset"); print(x); id_time(x,"ms")})
p("scru64 255", scru64(1,1,8,time=255)); p("scru64 256", id_time(scru64(1,1,8,time=256,rollback="reset"),"ms"))
p("scru64 max", {x<-scru64(1,1,8,time=282429536480*256-1,rollback="reset"); print(x); id_time(x,"ms")})
p("ksuid min", {x<-ksuid(1,time=1400000000000); print(x); id_time(x,"ms")}); p("ksuid below", ksuid(1,time=1400000000000-1))
p("ksuid max", {x<-ksuid(1,time=(1400000000+2^32-1)*1000+999); print(x); id_time(x,"ms")})
p("xid max", {x<-xid(1,time=(2^32-1)*1000+999); print(x); id_time(x,"ms")}); p("xid over", xid(1,time=2^32*1000)); p("xid 0", id_time(xid(1,time=0),"ms"))
p("objectid max", {x<-objectid(1,time=(2^32-1)*1000+999); print(x); id_time(x,"ms")})
p("time NA", uuid(1,time=NA_real_)); p("time len", uuid(3,time=c(1,2))); p("time Date", uuid(1,time=Sys.Date())); p("time chr", uuid(1,time="2024-01-01")); p("time POSIXlt", uuid(1,time=as.POSIXlt(tm)))
p("time int", id_time(uuid(1,time=5L),"ms")); p("time Inf", uuid(1,time=Inf)); p("time difftime", uuid(1, time=as.difftime(5, units="secs")))
p("time integer64-like classed", uuid(1, time=structure(5, class="foo")))
p("time decreasing in call", {x <- uuid(3, 7, time=c(ms+2000, ms, ms+1000)); id_time(x,"ms") - ms})
p("ulid decreasing", {x <- ulid(3, time=c(ms+2000, ms, ms+1000)); id_time(x,"ms") - ms})
p("ulid decreasing far", {x <- ulid(3, time=c(ms+200000, ms, ms+1000)); id_time(x,"ms") - ms})
p("ksuid decreasing", {x <- ksuid(3, time=c(ms+2000, ms, ms+1000)); id_time(x,"ms") - ms})
p("xid seq", id_fields(xid(3, random=as.raw(c(1,2,3,0xff,0xff,0xff)), time=tm))[,c("node","process","sequence")])
p("objectid seq", id_fields(objectid(3, random=as.raw(c(1,2,3,4,5,0xff,0xff,0xff)), time=tm))[,c("node","random","sequence")])

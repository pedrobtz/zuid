## Test environments

* local: macOS 15.7 (x86_64), R 4.5.2
* GitHub Actions (pedrobtz/r-actions): macOS, Windows and Ubuntu on
  R-release, Windows on R-devel, and Ubuntu on R-oldrel-1
* The `clang23`, `ubuntu-clang` and `ubuntu-gcc16` R-devel containers
  (pedrobtz/r-actions)
* `nosuggests` (no suggested packages installed) and `nold` (R-devel
  without long double)
* Additional checks in CI: ASan and UBSan (clang and gcc), valgrind, LTO,
  rchk, gctorture, `-fanalyzer`, `rcnst`, `rlibro`, and an hour of
  libFuzzer over the C parsers

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

## Data sources and copyright

The package vendors no code. Two tables are data taken unchanged from their
upstreams and compiled in: the Niceware word list (MIT, Copyright (c) 2016
yan) and the Sqids blocklist (MIT, Copyright (c) 2023 Sqids).
`inst/COPYRIGHTS` states their sources, pinned commits and licence, and the
`Copyright` field points to it. The tests carry TypeID's specification
fixtures (Apache-2.0, Jetify Inc.), with the licence beside them.

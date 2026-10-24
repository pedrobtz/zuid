/* The operating system's entropy source and clock (design.md D5, D6). Read
 * only by the R entry points, which pass the results to the generators. */

#include "zuid_gen.h"

#include <errno.h>
#include <string.h>

#if defined(_WIN32)
#  include <windows.h>
#  include <bcrypt.h>
#elif defined(__linux__)
#  include <sys/random.h>
#  include <fcntl.h>
#  include <unistd.h>
#  include <time.h>
#elif defined(__APPLE__)
#  include <sys/random.h>
#  include <time.h>
#else
#  include <stdlib.h>
#  include <time.h>
#endif

#if defined(__linux__)
/* /dev/urandom, for kernels older than getrandom(2). */
static int read_urandom(uint8_t *buf, size_t n)
{
    int fd = open("/dev/urandom", O_RDONLY | O_CLOEXEC);
    if (fd < 0) return -1;
    while (n > 0) {
        ssize_t got = read(fd, buf, n);
        if (got < 0 && errno == EINTR) continue;
        if (got <= 0) {
            close(fd);
            return -1;
        }
        buf += got;
        n -= (size_t) got;
    }
    close(fd);
    return 0;
}
#endif

int zuid_entropy(uint8_t *buf, size_t n)
{
#if defined(_WIN32)
    while (n > 0) {
        ULONG chunk = n > 0x10000000u ? 0x10000000u : (ULONG) n;
        if (!BCRYPT_SUCCESS(BCryptGenRandom(NULL, buf, chunk,
                                            BCRYPT_USE_SYSTEM_PREFERRED_RNG))) {
            return -1;
        }
        buf += chunk;
        n -= chunk;
    }
    return 0;
#elif defined(__linux__)
    while (n > 0) {
        ssize_t got = getrandom(buf, n, 0);
        if (got < 0 && errno == EINTR) continue;
        if (got < 0 && errno == ENOSYS) return read_urandom(buf, n);
        if (got <= 0) return -1;
        buf += got;
        n -= (size_t) got;
    }
    return 0;
#elif defined(__APPLE__)
    /* getentropy(3) returns at most 256 bytes per call. */
    while (n > 0) {
        size_t chunk = n > 256 ? 256 : n;
        if (getentropy(buf, chunk) != 0) return -1;
        buf += chunk;
        n -= chunk;
    }
    return 0;
#else
    arc4random_buf(buf, n);
    return 0;
#endif
}

const char *zuid_entropy_source(void)
{
#if defined(_WIN32)
    return "BCryptGenRandom";
#elif defined(__linux__)
    return "getrandom";
#elif defined(__APPLE__)
    return "getentropy";
#else
    return "arc4random_buf";
#endif
}

int64_t zuid_clock_now_100ns(void)
{
#if defined(_WIN32)
    /* 100 ns intervals since 1601-01-01. */
    FILETIME ft;
    GetSystemTimePreciseAsFileTime(&ft);
    uint64_t t = ((uint64_t) ft.dwHighDateTime << 32) | ft.dwLowDateTime;
    return (int64_t) (t - UINT64_C(116444736000000000));
#else
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    return (int64_t) ts.tv_sec * 10000000 + ts.tv_nsec / 100;
#endif
}

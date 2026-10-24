# zuid: Universally Unique Identifiers, Their Encodings and Their Kin

Parses, validates, inspects and generates universally unique identifiers
(UUIDs) of every version defined by RFC 9562
[doi:10.17487/RFC9562](https://doi.org/10.17487/RFC9562) , and
re-encodes them in alternative text forms such as Crockford base32,
base36, base58, base62, base64url, Proquint and Niceware words. The same
functions read the fields and creation time of related identifier
formats, including ULID, TypeID, UPID, SCRU128, SCRU64, KSUID,
Snowflake, XID, MongoDB ObjectId, NanoID, Cuid2, Sqids and content
identifiers (CID). Detection never assumes a format that the input does
not prove. Identifiers are generated from the operating system's entropy
source, never from R's random number generator. No dependencies.

## See also

Useful links:

- <https://github.com/pedrobtz/zuid>

- <https://pedrobtz.github.io/zuid/>

- Report bugs at <https://github.com/pedrobtz/zuid/issues>

## Author

**Maintainer**: Pedro Baltazar <pedrobtz@gmail.com> \[copyright holder\]

Authors:

- Pedro Baltazar <pedrobtz@gmail.com> \[copyright holder\]

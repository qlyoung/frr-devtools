/// Casts from uint8_t * to uint32_t *
/// Pointed-at uint32_t has alignment requirements
///
/// Quentin Young
@@
typedef uint32_t;
typedef uint8_t;
identifier x;
@@

uint8_t *x;
...

* (uint32_t *) x

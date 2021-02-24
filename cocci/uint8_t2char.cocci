/// uint8_t buffers are not char buffers.
///
// Confidence: High
// Copyright: (C) 2020 Quentin Young, GPLv2
// URL: http://coccinelle.lip6.fr/

@r1 exists@
identifier buf;
@@

- uint8_t
+ char
  buf[...];
... when any
- (char *)
  buf
// (
// sprintf((char *)buf, ...)
// |
// snprintf((char *)buf, ...)
// |
// strlcpy((char *)buf, ...)
// |
// strlcat((char *)buf, ...)
// |
// strcat((char *)buf, ...)
// |
// strlen((char *)buf, ...)
// )

/// Replace sprintf with snprintf when the buffer size is known
///
/// Replace snprintf(buf, size_expr, ...) with snprintf(buf, sizeof(buf), ...)
/// where possible
///
/// Replace sprintf(buf + strlen(buf), ...) with:
/// - char tmp[sizeof(buf)];
/// - snprintf(tmp, ...);
/// - strlcat(buf, tmp, sizeof(buf));
///
/// This last one relies on VLAs being available.
///
// Confidence: High
// Copyright: (C) 2020 Quentin Young, GPLv2
// URL: http://coccinelle.lip6.fr/

@r1 exists@
identifier buf;
@@

char buf[...];
... when any
- sprintf(buf,
+ snprintf(buf,
+         sizeof(buf),
          ...);

@r2 exists@
expression sz;
identifier buf;
@@

char buf[sz];
...
snprintf(buf,
-        sz,
+        sizeof(buf),
         ...);

@r3 exists@
identifier buf;
@@

char buf[...];
...
+ char tmp[sizeof(buf)];

- sprintf(buf + strlen(buf),
+ snprintf(tmp,
+          sizeof(tmp),
          ...);
+ strlcat(buf, tmp, sizeof(buf));


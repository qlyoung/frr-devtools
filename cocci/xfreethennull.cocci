/// Null after free
///
// Confidence: High
// Copyright: (C) 2013 Julia Lawall, INRIA/LIP6.  GPLv2.
// Copyright: (C) 2019 Quentin Young.  GPLv2.
// URL: http://coccinelle.lip6.fr/
// Comments:
// Options: --no-includes --include-headers

@@
expression e, t;
identifier f;
@@

XFREE(t, e)
...
- e = NULL;

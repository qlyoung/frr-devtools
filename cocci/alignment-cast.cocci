/// Cast of uint8_t * to anything larger constitutes an alignment issue.
///
// Confidence: High
// Copyright: (C) 2020 Quentin Young.  GPLv2.
// URL: http://coccinelle.lip6.fr/
// Comments:
// Options: --no-includes --include-headers

@r@
typedef uint8_t, uint16_t, uint32_t;
{uint8_t, uint16_t} * x;
@@

* ... (uint32_t *) x


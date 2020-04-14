/// Use array_size instead of dividing sizeof array with sizeof an element
///
//# This makes an effort to find cases where array_size can be used such as
//# where there is a division of sizeof the array by the sizeof its first
//# element or by any indexed element or the element type. It replaces the
//# division of the two sizeofs by array_size.
//
// Confidence: High
// Copyright: (C) 2014 Himangi Saraogi.  GPLv2.
// Copyright: (C) 2020 Quentin Young.  GPLv2.
// Comments:
// Options: --no-includes --include-headers

@@
type T;
T *x;
@@
(
* sizeof(x)
)

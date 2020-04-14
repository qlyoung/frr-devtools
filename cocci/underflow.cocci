/// Unsigned expressions cannot be lesser than zero. Presence of
/// comparisons 'unsigned (<|<=|>|>=) 0' often indicates a bug,
/// usually wrong type of variable.
///
// Confidence: Average
// Copyright: (C) 2015 Andrzej Hajda, Samsung Electronics Co., Ltd. GPLv2.
// Portions: (C) 2020 Quentin Young, GPLv2
// URL: http://coccinelle.lip6.fr/

@r_cmp@
position p;
typedef bool, uint8_t, uint16_t, uint32_t, uint64_t;
{unsigned char, unsigned short, unsigned int, unsigned long, unsigned long long,
	size_t, bool, uint8_t, uint16_t, uint32_t, uint64_t} v;
expression e;
@@

\( v = e \| &v \)
...
* (\( v@p < 0 \| v@p <= 0 \| v@p >= 0 \))

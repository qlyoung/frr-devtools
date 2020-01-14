/// Casts from uint8_t * to uint32_t *
/// Pointed-at uint32_t has alignment requirements
///
/// Quentin Young
@@
vrf_id_t E;
@@

- E = 0
+ E = VRF_DEFAULT

@@
vrf_id_t E;
@@

- E == 0
+ E == VRF_DEFAULT

@@
vrf_id_t E;
@@

- !E
+ E != VRF_DEFAULT

# G-SCH-01 Geometry Amendment (must follow)

From UX Research Amendment — build against this, not freeform SVG art:

1. **Hybrid:** parametric skeleton (axes, BB, HT, ST stable) + **4 presets** (road/gravel/mtb/city). NOT 8 copy-paste polygons. NOT one drawing stretched for all sports.
2. **viewBox:** `0 0 1000 500` (2:1). Ground / axle Y **constant** across sport switch — **no scale-jump**.
3. **BB locked** in skeleton (same BB coords across presets; tubes meet BB).
4. **MTB HTA ~65°** (not ~73° everywhere). Road ~72.5°, Gravel/City ~71°.
5. **Recognition hierarchy:** MTB = fat tires + travel + short stem + long WB; City = rack+fenders+upright bars; Gravel = drops + fatter tires; Road = drops + thin tires + compact WB.
6. Hotspot IDs/coords from garage-bike-schema-spec-v1.md §3; hit ≥44pt; overlap priority pedals > crank > chain > frame.

If current SVG drafts violate BB lock / scale-jump / HTA, fix before PR.

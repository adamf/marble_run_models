// =====================================================================
//  Marble-Run Base Plate  -  parametric, tileable, print-in-place
//  For National Geographic (and most translucent OEM) marble runs
//  Author: generated for Adam
//
//  HOW IT WORKS
//  ------------
//  A flat plate carries a grid of hollow pegs. Each peg is sized to
//  plug INTO the female (open) end of a marble-run tube, the same way
//  the tubes' own male spigots plug into each other. Stand a tube on a
//  peg and it can't tip. Pegs sit on a square grid whose pitch you set
//  to your set's module length, so horizontal pieces span whole grid
//  units. Plates interlock with jigsaw tabs so you can tile a big field.
//
//  >>> YOU MUST CALIBRATE peg_od TO YOUR TUBES <<<
//  Print marble_run_calibration.stl first (PART="calibration"),
//  push a real tube onto each test peg, pick the snuggest, and set
//  peg_od to that number below. Then print the tiles.
// =====================================================================

PART = "tile";          // "tile"  or  "calibration"

// ---------- GRID ----------
grid_x       = 6;       // pegs across
grid_y       = 6;       // pegs deep
span_mod     = 100;     // measured span/ramp foot-to-foot center-to-center
subs_per_span = 3;      // pegs the span spans (feet land on pegs
                        //     subs_per_span cells apart, with subs-1
                        //     intermediate support pegs sitting under the
                        //     span body). Denser = more column-support
                        //     pegs. Limit: pitch > peg_od (no overlap), so
                        //     subs_per_span < span_mod/peg_od ~= 4.2, i.e.
                        //     max 4 (but 4 leaves only ~1mm gap between
                        //     peg edges - risky to print). 3 is comfy.
pitch        = span_mod / subs_per_span;
                        // == 100/3 = 33.333mm. Grid continuity (pegs at
                        // pitch/2 from every edge) means a span also fits
                        // across a seam: A's last peg sits pitch/2 from
                        // the seam, then N-1 intermediate pegs on B, then
                        // B's N-th peg lands 100mm from A_last.

// ---------- PEG (the bit that plugs into a tube) ----------
peg_od       = 23.7;    // <-- CALIBRATED for user's Bambu + Nat-Geo tubes:
                        //     firm/snug fit. Progression: 25.4 -> 24.0 ->
                        //     23.9 -> 23.8 -> 23.7 as the user dialed in a
                        //     slightly easier on/off.
                        //     Outer dia of peg = female-socket ID of your
                        //     tubes minus a snug clearance.
peg_wall     = 1.8;     // peg wall thickness (hollow peg flexes = grip)
peg_h        = 8;       // how far the peg sticks up
peg_top_cham = 1.2;     // lead-in chamfer at peg tip (easier to seat)
peg_flare_h  = 2.0;     // internal flare at the peg's base: the bore
                        //     tapers from fully closed at the underside up
                        //     to the nominal bore radius over this height,
                        //     then continues straight to the top. The wall
                        //     is thick at the base for strength, and the
                        //     outer stays flat at peg_od so tube feet seat
                        //     flush against the plate (no external lip).

// ---------- BASE ----------
base_th      = 3.0;     // plate thickness
edge_cham    = 0.8;     // top-perimeter chamfer (nicer to handle)

// ---------- TILE-TO-TILE CONNECTORS (jigsaw) ----------
connectors_on   = true;
conn_cells      = [1, 4];  // which edge grid-cells become connectors
                           // (0-indexed). Those edge pegs are omitted to
                           // make room. [1,4] = 2 per edge on a 6-wide,
                           // symmetric and clear of the corners.
tab_reach   = 12;       // how far a tab sticks out
tab_neck_w  = 8;        // neck width
tab_head_d  = 10;       // head diameter (>neck = it catches). Kept only
                        //   modestly larger so tiles PRESS together with
                        //   PLA's natural edge flex instead of needing a
                        //   hard snap that could crack.
tab_tol     = 0.40;     // clearance in the socket. Bigger = looser.
                        //   Too stiff to press together? raise to 0.6.
                        //   Falls apart? lower to 0.25.

// ---------- quality ----------
$fn = 64;

// ================= derived =================
plate_w = grid_x * pitch;   // physical footprint = N*pitch  -> grid stays
plate_d = grid_y * pitch;   // continuous across tiles (border = pitch/2)
eps = 0.01;

// ================= modules =================

// one hollow peg centered at origin, base sitting on z=0
module peg() {
    r  = peg_od/2;
    ri = r - peg_wall;
    // straight outer shaft (no external skirt) + tapered internal bore.
    difference() {
        union() {
            cylinder(h=peg_h - peg_top_cham, r=r);
            translate([0,0,peg_h - peg_top_cham])
                cylinder(h=peg_top_cham, r1=r, r2=r-peg_top_cham);
        }
        // bore: closed at the underside (r=0) tapering out to ri over
        // peg_flare_h -> reinforced base without any outer bump; then
        // straight ri up through and out the top.
        union() {
            cylinder(h=peg_flare_h, r1=0, r2=ri);
            translate([0,0,peg_flare_h - eps])
                cylinder(h=peg_h+1, r=ri);
        }
    }
}

// 2D jigsaw profile, protruding along +Y from the seam line y=0
module jigsaw2d(reach, neck_w, head_d, grow=0) {
    hr = head_d/2 + grow;
    nw = neck_w + 2*grow;
    hull_y = reach - head_d/2;      // head center
    union() {
        // neck
        translate([0,(hull_y)/2])
            square([nw, hull_y + eps], center=true);
        // head
        translate([0, hull_y]) circle(r=hr);
    }
}

// a connector TAB (adds material), seam at y=0, sticks toward +Y
module tab3d() {
    linear_extrude(base_th) jigsaw2d(tab_reach, tab_neck_w, tab_head_d, 0);
}
// a connector SOCKET (removes material), seam at y=0, opens toward -Y
module socket3d() {
    // mirror of the tab, grown by tolerance, pushed a hair past the seam
    translate([0,eps,-eps])
        linear_extrude(base_th+2*eps)
            jigsaw2d(tab_reach, tab_neck_w, tab_head_d, tab_tol);
}

// is edge-cell index k one of the connector cells?
function is_conn(k) = connectors_on &&
    len(search(k, conn_cells)) > 0;

// ================= the tile =================
module tile() {
    difference() {
        union() {
            // ---- base slab with chamfered top perimeter ----
            difference() {
                cube([plate_w, plate_d, base_th]);
                // chamfer top edges
                if (edge_cham > 0)
                    perimeter_chamfer();
            }

            // ---- pegs (skip edge cells that host a connector) ----
            for (i=[0:grid_x-1], j=[0:grid_y-1]) {
                on_left   = (i==0);
                on_right  = (i==grid_x-1);
                on_front  = (j==0);
                on_back   = (j==grid_y-1);
                // omit a peg only if it sits on an edge AND that edge cell
                // (indexed along the edge) is a connector cell
                skip =
                    (on_left   && is_conn(j)) ||
                    (on_right  && is_conn(j)) ||
                    (on_front  && is_conn(i)) ||
                    (on_back   && is_conn(i));
                if (!skip)
                    translate([(i+0.5)*pitch, (j+0.5)*pitch, base_th - eps])
                        peg();
            }

            // ---- connector TABS on +X and +Y edges ----
            if (connectors_on) {
                for (j=[0:grid_y-1]) if (is_conn(j))   // +X (right) edge
                    translate([plate_w, (j+0.5)*pitch, 0])
                        rotate([0,0,-90]) tab3d();
                for (i=[0:grid_x-1]) if (is_conn(i))   // +Y (back) edge
                    translate([(i+0.5)*pitch, plate_d, 0])
                        tab3d();
            }
        }

        // ---- connector SOCKETS on -X and -Y edges ----
        // socket3d() opens toward +Y from y=0, so it must be aimed INTO the
        // plate. On -Y edge that means no rotation; on -X edge rotate -90
        // around Z so +Y -> +X. (Bug: +90/+180 aimed sockets outward and
        // left the edges with tabs but no pockets.)
        if (connectors_on) {
            for (j=[0:grid_y-1]) if (is_conn(j))        // -X (left) edge
                translate([0, (j+0.5)*pitch, 0])
                    rotate([0,0,-90]) socket3d();
            for (i=[0:grid_x-1]) if (is_conn(i))        // -Y (front) edge
                translate([(i+0.5)*pitch, 0, 0])
                    socket3d();
        }
    }
}

module perimeter_chamfer() {
    c = edge_cham;
    // four top edges as triangular prisms subtracted
    translate([0,0,base_th-c]) {
        // along X (front & back)
        for (yy=[0, plate_d])
            translate([-1, yy, 0])
                rotate([45,0,0])
                    cube([plate_w+2, c*1.5, c*1.5]);
        // along Y (left & right)
        for (xx=[0, plate_w])
            translate([xx, -1, 0])
                rotate([0,-45,0])
                    cube([c*1.5, plate_d+2, c*1.5]);
    }
}

// ================= calibration strip =================
// A row of pegs at increasing diameter. Push a real tube onto each,
// find the snuggest, read the number, set peg_od to it.
cal_first = 24.0;
cal_step  = 0.5;
cal_count = 7;      // 24.0 .. 27.0
cal_sp    = 30;     // spacing between test pegs

module calibration() {
    w = (cal_count) * cal_sp;
    d = 42;
    union() {
        difference() {
            cube([w, d, base_th]);
        }
        for (n=[0:cal_count-1]) {
            od = cal_first + n*cal_step;
            translate([(n+0.5)*cal_sp, d*0.62, base_th-eps])
                peg_od_override(od) ;
            // embossed number
            translate([(n+0.5)*cal_sp, d*0.20, base_th])
                linear_extrude(1.0)
                    text(str(od), size=7, halign="center", valign="center",
                         font="Liberation Sans:style=Bold");
        }
    }
}
// helper: draw a peg with a specific OD (mirrors peg())
module peg_od_override(od) {
    r=od/2; ri=r-peg_wall;
    difference(){
        union(){
            cylinder(h=peg_h-peg_top_cham, r=r);
            translate([0,0,peg_h-peg_top_cham])
                cylinder(h=peg_top_cham, r1=r, r2=r-peg_top_cham);
        }
        union(){
            cylinder(h=peg_flare_h, r1=0, r2=ri);
            translate([0,0,peg_flare_h - eps])
                cylinder(h=peg_h+1, r=ri);
        }
    }
}

// ================= render =================
if (PART == "tile")            tile();
else if (PART == "calibration") calibration();

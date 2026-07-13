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
grid_x       = 5;       // pegs across
grid_y       = 5;       // pegs deep
pitch        = 30;      // <-- center-to-center spacing (mm). Set to your
                        //     set's module: measure foot-to-foot of a
                        //     horizontal piece, or use tube OD + ~1mm.

// ---------- PEG (the bit that plugs into a tube) ----------
peg_od       = 24.0;    // <-- CALIBRATED for user's Bambu + Nat-Geo tubes:
                        //     firm/snug fit. 23.5 is slightly looser.
                        //     Outer dia of peg = female-socket ID of your
                        //     tubes minus a snug clearance.
peg_wall     = 1.8;     // peg wall thickness (hollow peg flexes = grip)
peg_h        = 8;       // how far the peg sticks up
peg_top_cham = 1.2;     // lead-in chamfer at peg tip (easier to seat)
peg_skirt    = 1.6;     // extra radius flare where peg meets plate (strength)
peg_skirt_h  = 2.0;

// ---------- BASE ----------
base_th      = 3.0;     // plate thickness
edge_cham    = 0.8;     // top-perimeter chamfer (nicer to handle)

// ---------- TILE-TO-TILE CONNECTORS (jigsaw) ----------
connectors_on   = true;
conn_cells      = [1, 3];  // which edge grid-cells become connectors
                           // (0-indexed). Those edge pegs are omitted to
                           // make room. [1,3] = 2 per edge on a 5-wide.
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
    union() {
        // skirt (conical flare at the bottom for strength)
        cylinder(h=peg_skirt_h, r1=r+peg_skirt, r2=r);
        // shaft with hollow bore + top chamfer
        difference() {
            union() {
                cylinder(h=peg_h - peg_top_cham, r=r);
                translate([0,0,peg_h - peg_top_cham])
                    cylinder(h=peg_top_cham, r1=r, r2=r-peg_top_cham);
            }
            // bore, open at top
            translate([0,0,peg_skirt_h])
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
// helper: draw a peg with a specific OD
module peg_od_override(od) {
    r=od/2; ri=r-peg_wall;
    union(){
        cylinder(h=peg_skirt_h, r1=r+peg_skirt, r2=r);
        difference(){
            union(){
                cylinder(h=peg_h-peg_top_cham, r=r);
                translate([0,0,peg_h-peg_top_cham])
                    cylinder(h=peg_top_cham, r1=r, r2=r-peg_top_cham);
            }
            translate([0,0,peg_skirt_h]) cylinder(h=peg_h+1, r=ri);
        }
    }
}

// ================= render =================
if (PART == "tile")            tile();
else if (PART == "calibration") calibration();

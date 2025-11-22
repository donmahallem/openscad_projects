// Parameters
// base size in mm per tile
size_x = 50;//[20:50]
// Tiles in x direction
size_y = 80;//[20:20]
// Tiles in y direction
depth = 20;//[5:20]
// Tiles in z direction
lip_depth =2; //[2:20]

wall_thickness =4;

inner_radius= 1;
chamfer = 0.6;
// Lip size around
lip_size = 10; ///

rib_thickness = 1.6;

rib_angle=45;
ribs = 10;
rib_height = 7;

bore_holes = true;

$fa = 1;
$fs = 1;



module rounded_rectangle(size_x, size_y, corner_radius) {
    // Ensure the corner radius does not exceed half the smallest dimension
    r = min(corner_radius, size_x/2, size_y/2);
    difference() {
        square([size_x, size_y], center=true);
        for (dx=[-1,1], dy=[-1,1]) {
            translate([dx*(size_x/2 - r), dy*(size_y/2 - r)])
                difference() {
                    square([2*r, 2*r], center=true);
                    translate([0,0])
                        circle(r, $fn=48);
                }
        }
    }
    // Add the rounded corners
    for (dx=[-1,1], dy=[-1,1]) {
        translate([dx*(size_x/2 - r), dy*(size_y/2 - r)])
            circle(r, $fn=48);
    }
}

module profile(){
    order = 10;
    angles=[ for (i = [0:order-1]) i*(90/order) ];
    outer_lip = inner_radius+wall_thickness+lip_size;
    coords=[
        [inner_radius+chamfer,0],
        [outer_lip-chamfer,0],
        [outer_lip, chamfer],
        [outer_lip, lip_depth-chamfer],
        [outer_lip-chamfer, lip_depth],
        [inner_radius+wall_thickness,lip_depth],
        [inner_radius+wall_thickness,depth-chamfer],
        [inner_radius+wall_thickness-chamfer,depth],
        [inner_radius+chamfer,depth],
        [inner_radius,depth-chamfer],
        [inner_radius,chamfer]
    ];
    polygon(coords);
}

// Example usage:
module rounded_rectangle(x,y,r){
    order = 10;
    angles=[ for (i = [0:order-1]) i*(90/order) ];
    coords=[
        for (th=angles) [(x-r)+r*cos(th+270), r+r*sin(th+270)],
        for (th=angles) [(x-r)+r*cos(th+0), (y-r)+r*sin(th+0)],
        for (th=angles) [r+r*cos(th+90), (y-r)+r*sin(th+90)],
        for (th=angles) [r+r*cos(th+180), r+r*sin(th+180)],
    ];
    polygon(coords);
 }


module v1(){
    difference(){
        union(){
            linear_extrude(lip_depth)
                translate([-size_x/2-lip_size,-size_x/2-lip_size,0])
                rounded_rectangle(size_x+(2*lip_size),size_y+(2*lip_size),lip_size+wall_thickness+1);
            linear_extrude(depth)
                translate([-size_x/2,-size_x/2,0])
                rounded_rectangle(size_x,size_y,wall_thickness+1);    
        }
        inner_tube_x=size_x-(2*wall_thickness);
        inner_tube_y=size_y-(2*wall_thickness);
        linear_extrude(depth)
                translate([-inner_tube_x/2,-inner_tube_y/2,0])
                rounded_rectangle(inner_tube_x,inner_tube_y,1);    
    }
}

module duct_corner(){
    rotate_extrude(angle=90)
        profile();
}

module duct_straight(l){
    linear_extrude(l) profile();
}

module duct_outer(){
    union(){
        diff =inner_radius+wall_thickness;
        x_wall_length = size_x-(2*(inner_radius+wall_thickness));
        y_wall_length = size_y-(2*(inner_radius+wall_thickness));
        translate([diff,diff,0]) rotate([0,0,180]) duct_corner();
        translate([diff,y_wall_length+diff,0]) rotate([0,0,90]) duct_corner();
        translate([diff+x_wall_length,diff,0]) rotate([0,0,270]) duct_corner();
        translate([x_wall_length+diff,y_wall_length+diff,0]) duct_corner();
        translate([x_wall_length+diff,diff,0]) rotate([90,0,-90]) duct_straight(x_wall_length);
        translate([diff,y_wall_length+diff,0]) rotate([90,0,90]) duct_straight(x_wall_length);
        translate([diff,diff,0]) rotate([90,0,180]) duct_straight(y_wall_length);
        translate([x_wall_length+diff,y_wall_length+diff,0]) rotate([90,0,0]) duct_straight(y_wall_length);
    }
}


module rib(thickness,w,h,angle){
    diff = tan(angle)*h;
    coords=[
        [0,0],
        [thickness,0],
        [thickness+diff,h],
        [diff,h]
    ];
    translate([wall_thickness/2,0,0]) rotate([90,0,90]) linear_extrude(size_x-wall_thickness) polygon(coords);
}

module full_duct(){

    rib_height_actual = min(depth,rib_height);
    union(){
        diff = tan(rib_angle)*rib_height_actual;
        duct_outer();
        rib_offset_a=wall_thickness-rib_thickness-chamfer;
        rib_spacing=(size_y-diff-wall_thickness-rib_offset_a)/(ribs-1);
        for (i = [0:ribs-1]) {
            translate([0,rib_offset_a+(i*rib_spacing),0]) rib(rib_thickness,50,rib_height_actual,rib_angle);
        }

    }
}


if bore_holes{
    full_duct();
}else{
    full_duct();
}
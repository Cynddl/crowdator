open Dataset
open Evolution
open Hopfield
open Graphics2D
open Primitives


(* Déplacement à l'aide d'un réseau de Hopfield *)

let pas = 0.5
let angle_factor = 0.3

let hop_input someone m =
	let pos_out = m#get_exit someone#point in
	let dx = pos_out.x -. someone#point.x in
	let dy = pos_out.y -. someone#point.y in
	let future_angle = atan (dy/.dx) in
	let dteta =  (future_angle -. someone#angle) in
	let f = function
		| true -> 1.
		| false -> -. 1. in
	Array.append (Array.map f (get_sensors_col someone m)) [|dteta|]


let update_angle someone m ~hop =
	let arr = hop_input someone m in
	if (hop#get_rule arr).(0) = 1. then
		someone#set_angle (someone#angle +. (hop#get_rule arr).(1) *. angle_factor)
	else ()

let update_one someone m ~hop =
	let p = someone#point in
	update_angle someone m ~hop;
	let future_pos = {x=p.x +. pas *. cos someone#angle; y=p.y +. pas *. sin someone#angle} in
	if not (is_there_future_col_people someone m future_pos) then
		someone#set_point future_pos

let update m ~hop =
	List.iter (fun p -> update_one p m ~hop) m#people

let remove_escaped m =
	m#set_people (List.filter (fun p0->dist p0#point (m#get_final_exit) > 5.*.p0#radius) m#people)
	
let iterate m ~display ~hop =
	update m ~hop;
	remove_escaped m;
	if display then 
	(Primitives.wait 200; redraw m )

let test_hop ~display hop =
	
	let my_map = new map {x=42.; y=10.} in
	my_map#add_person (new person {x=5.; y=18.}  (Random.float_range 0. 1.));
	my_map#add_person (new person {x=10.; y=13.}  (Random.float_range 0. 1.));
	my_map#add_person (new person {x=5.; y=10.}  (Random.float_range 0. 1.));
	
	
	my_map#add_wall (fast_wall 2. 42. 42. 42.);
	my_map#add_wall (fast_wall 2. 2. 2. 42.);
	my_map#add_wall (fast_wall 2. 2. 42. 2.);
	my_map#add_wall (fast_wall 42. 2. 42. 42.);
	
	my_map#add_wall (fast_wall 30. 2. 30. 30.);
	my_map#add_wall (fast_wall 20. 20. 20. 42.);
	
	my_map#add_box (fast_box 2. 2. 20. 42. 25. 10.);
	my_map#add_box (fast_box 20. 2. 30. 42. 32. 40.);
	my_map#add_box (fast_box 30. 2. 42. 42. 42. 10.);
		
	
	(* Au plus 100 itérations *)
	let rec loop n = match (n, key_pressed () || List.length my_map#people = 0) with
		| (_, true)
		| (0, _) -> ()
		| (_ , false) ->
			(iterate my_map ~display ~hop; loop (n-1))
	in loop 200;
	List.length my_map#people


let _ =
	Random.self_init ();

	start_display;
	let hop = new Hopfield.t 8 4 2 Hopfield.step in
	hop#init;

	let pop1 = HopfieldEvoluate.generate_population hop 3. 100 in
	let best1 = HopfieldEvoluate.choose_best (test_hop ~display:false) pop1 in

	let pop2 = HopfieldEvoluate.generate_population best1 1. 100 in
	let best2 = HopfieldEvoluate.choose_best (test_hop ~display:false) pop2 in

	let pop3 = HopfieldEvoluate.generate_population best2 1. 100 in
	let best3 = HopfieldEvoluate.choose_best (test_hop ~display:false) pop3 in

	Printf.printf "%d\n" (test_hop ~display:true best3)


open Dataset
open Event
open Evolution
open Hopfield
open Graphics2D
open Primitives

(* Déplacement à l'aide d'un réseau de Hopfield *)


let remove_escaped m =
    let func = fun p0 -> dist p0#point (m.final_exit) < 5.*.p0#radius in
    let new_people, removed = RtreePeople.remove_by_condition func m.people in
    let new_id_list = List.filter (fun i -> not (List.exists (fun p -> Person.get_id p = i) removed)) m.id_list in
    {m with
        people = new_people;
        id_list =new_id_list
    }
	
let iterate (m:map) ~hop ~display =
	let m0 = update_map m ~hop in 
	let m1 = remove_escaped m0 in
	if display then 
	    (* Pause de 100 ms *)
	    (wait 100; redraw m1);
	m1


let test_map ?(display=false) ?(max_time=200) map hop =
	let rec loop m n =
	    if RtreePeople.size m.people = 0 || n = 0 then
	        m
	    else
	        (let m0 = iterate map ~hop ~display:false in loop m0 (n-1))
	in
	    let rec loop_display m n polling =
	        if RtreePeople.size m.people = 0 || n = 0 then
	            m
    	    else match wait_next_event (if polling then [Poll;Key_pressed] else [Key_pressed]) with
    	        | status when status.keypressed ->
    	            (match parse_keypressed status.key with
    	                | Zoom dir ->
    	                    (zoom_screen dir; let m0 = iterate map ~display ~hop in loop_display m0 (n-1) false)
    	                | Move dir ->
    	                    (move_screen dir; let m0 = iterate map ~display ~hop in loop_display m0 (n-1) false)
    	                | NoDisplay ->
    	                    (let m0 = iterate map ~display ~hop in loop m0 (n-1))
    	                | Quit ->
    	                    m
    	                | Nothing ->
    	                    (let m0 = iterate map ~display ~hop in loop_display m0 (n-1) (not polling)))
    	        | _ -> 
    			    (let m0 = iterate map ~display ~hop in loop_display m0 (n-1) true)
	in
	    let last_map =
	        (
	            if display then
	                loop_display map max_time true
                else
                    loop map max_time
            )
        in
        RtreePeople.size last_map.people


let fast_test_map ?(display=false) map neural_net =
	let people_list =
        [(new person {x=10.; y=18.}  (Random.float_range 0. 1.));
         (new person {x=15.; y=13.}  (Random.float_range 0. 1.));
         (new person {x=10.; y=10.}  (Random.float_range 0. 1.))]
    in
    let m = add_map_people map people_list in
    test_map ~display m neural_net
	
let close_test_map map neural_net =
    let people_list =
        [(new person {x=10.; y=15.}  (Random.float_range 0. 1.));
         (new person {x=15.; y=13.}  (Random.float_range 0. 1.));
         (new person {x=10.; y=10.}  (Random.float_range 0. 1.))]
    in
    let m = add_map_people map people_list in
    test_map m neural_net


let deep_test ?(display=false) map neural_net =
    let people_list =
        map_range 3 7 (fun i j -> new person {x=5.+.4.*.float_of_int i; y=5.+.4.*.float_of_int j}  (Random.float_range 0. 1.)) in
    let m = add_map_people map people_list in
	test_map m neural_net ~display ~max_time:300
	
(*let final_test ?(display=false) map neural_net =
    map.people <- map_range 5 5 (fun i j -> new person {x=2.+.4.*.float_of_int i; y=2.+.4.*.float_of_int j}  (Random.float_range 0. 1.));
    test_map map neural_net ~display ~max_time:300
	
let blank_test ?(display=false) map neural_net =
    test_map map neural_net ~display ~max_time:300*)

let _ =
	Random.self_init ();
	
	let walls =
		[
			(fast_wall 2. 42. 42. 42.);
			(fast_wall 2. 2. 2. 42.);
			(fast_wall 2. 2. 42. 2.);
			(fast_wall 42. 2. 42. 42.);
			(fast_wall 30. 2. 30. 25.);
			(fast_wall 30. 30. 30. 42.);
			(fast_wall 20. 20. 20. 42.)
		] in
	let boxes = 
		[
			(fast_box 2. 2. 20. 42. 25. 10.);
		    (fast_box 20. 2. 30. 42. 32. 28.);
		    (fast_box 30. 2. 42. 42. 38. 10.)
		] in
	let my_map = 
		{
			w = 42;
			h = 42;
			obstacles = RtreeObstacle.insert_list (fast_make_obstacle_list walls) RtreeObstacle.empty;
			people = RtreePeople.Empty;
			id_list = [];
			boxes = boxes;
			final_exit = {x=40.; y=12.}
		}
	in
	
	let walls2 =
	    [
	        (* Murs extérieurs *)
	        fast_wall 0. 0. 50. 0.;
	        fast_wall 0. 0. 0. 50.;
	        fast_wall 0. 50. 50. 50.;
	        fast_wall 50. 0. 50. 50.;
	        (* Murs intérieurs *)
	        fast_wall 30. 0. 30. 20.;
	        fast_wall 30. 25. 30. 50.;
	        fast_wall 25. 21. 25. 24.
	    ]
	in
	let boxes2 = 
	    [
	        fast_box 0. 0. 30. 50. 35. 22.;
	        fast_box 30. 0. 50. 50. 45. 25.;
        ]
	in
	let final_map =
	    {
	        w = 50;
	        h = 50;
	        obstacles = RtreeObstacle.insert_list (fast_make_obstacle_list walls2) RtreeObstacle.Empty;
	        boxes = boxes2;
	        people = RtreePeople.Empty;
	        id_list = [];
	        final_exit = {x=45.; y=25.}
	    }

	in

	let hop = new Hopfield.t 20 4 1 Hopfield.step in
	hop#init;

    let best1 = HopfieldEvoluate.elect_one hop 2. 1 (fast_test_map my_map) in
    Printf.printf "%d\n" (fast_test_map my_map best1); flush stdout;

    let best2 = HopfieldEvoluate.elect_one best1 2. 1 (close_test_map my_map) in
    Printf.printf "%d\n" (fast_test_map my_map best2); flush stdout;

    let best3 = HopfieldEvoluate.elect_one best2 1. 1 (deep_test my_map) in
    Printf.printf "%d\n" (fast_test_map my_map best3); flush stdout;

	if fast_test_map my_map best3 < 2 then
		Printf.printf "%d\n" (deep_test ~display:true my_map best3)
	else
		Printf.printf "Désolé, je suis encore trop jeune pour toi.\n"
push!(LOAD_PATH, "./modules")

include("scan.jl");
include("traffic.jl");
include("music.jl");
include("internet.jl");
include("powergrid.jl");
include("minnesota.jl");
include("wsn.jl");
include("fx.jl");

scan("Anaheim",         () -> read_Transportation("Anaheim"),       false, "ori", 0.01:0.01:0.95);
scan("Barcelona",       () -> read_Transportation("Barcelona"),     false, "ori", 0.01:0.01:0.95);
scan("Winnipeg",        () -> read_Transportation("Winnipeg"),      false, "ori", 0.01:0.01:0.95);
scan("ChicagoSketch",   () -> read_Transportation("ChicagoSketch"), false, "ori", 0.01:0.01:0.95);
scan("Music_Song01",    () -> read_Music(Inf, "song"),              false, "ori", 0.01:0.01:0.95, 1:3);
scan("Music_Artist01",  () -> read_Music(Inf, "artist"),            false, "ori", 0.01:0.01:0.95, 1:3);
scan("Minnesota",       () -> read_Minnesota(),                     false, "syn", 0.01:0.01:0.95, [1,3,4,5]);
scan("Powergrid",       () -> read_Powergrid(),                     false, "syn", 0.01:0.01:0.95, [1,3,4,5]);
scan("Balerma",         () -> read_WSN(),                           false, "syn", 0.01:0.01:0.95, [1,3,4,5]);
scan("Internet",        () -> read_Internet(),                      false, "syn", 0.01:0.01:0.95, [1,3,4,5]);
test_FX();

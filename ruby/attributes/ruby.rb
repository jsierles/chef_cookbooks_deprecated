# twitter GC settings from http://blog.evanweaver.com/articles/2009/04/09/ruby-gc-tuning/
default.ruby[:gc][:heap_min_slots] = 500000
default.ruby[:gc][:heap_slots_increment] = 250000
default.ruby[:gc][:heap_slots_growth_factor] = 1
default.ruby[:gc][:malloc_limit] = 50000000
default.ruby[:gc][:heap_free_min] = 4096
default.ruby[:gc][:enabled] = true

default.ruby[:bin_path] = ruby[:gc][:enabled] ? "#{ruby[:bin_dir]}/ruby_gc_wrapper" : "#{ruby[:bin_dir]}/ruby"
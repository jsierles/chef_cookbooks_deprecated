template "#{node[:languages][:ruby][:bin_dir]}/ruby_gc_wrapper" do
  source "ruby_gc_wrapper.sh.erb"
  mode 0755
end
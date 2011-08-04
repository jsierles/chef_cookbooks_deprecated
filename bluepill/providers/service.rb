require 'chef/mixin/command'
require 'chef/mixin/language'
include Chef::Mixin::Command

action :enable do
  unless @bp.enabled
    link "#{node['bluepill']['init_dir']}/#{new_resource.service_name}" do
      to node['bluepill']['bin']
      only_if { ::File.exists?("#{node['bluepill']['conf_dir']}/#{new_resource.service_name}.pill") }
    end
  end
end

action :load do
  unless @bp.running
    execute "#{node['bluepill']['bin']} load #{node['bluepill']['conf_dir']}/#{new_resource.service_name}.pill"
  end
end

action :start do
  unless @bp.running
    execute "#{node['bluepill']['bin']} #{new_resource.service_name} start"
  end
end

action :disable do
  if @bp.enabled
    file "#{node['bluepill']['conf_dir']}/#{new_resource.service_name}.pill" do
      action :delete
    end
    link "#{node['bluepill']['init_dir']}/#{new_resource.service_name}" do
      action :delete
    end
  end
end

action :stop do
  if @bp.running
    execute "#{node['bluepill']['bin']} #{new_resource.service_name} stop"
  end
end

action :restart do
  if @bp.running
    execute "#{node['bluepill']['bin']} #{new_resource.service_name} restart"
  end
end

def load_current_resource
  @bp = Chef::Resource::BluepillService.new(new_resource.name)
  @bp.service_name(new_resource.service_name)

  Chef::Log.debug("Checking status of service #{new_resource.service_name}")

  begin
    if run_command_with_systems_locale(:command => "#{node['bluepill']['bin']} status #{new_resource.service_name}") == 0
      @bp.running(true)
    end
  rescue Chef::Exceptions::Exec
    @bp.running(false)
    nil
  end

  if ::File.exists?("#{node['bluepill']['conf_dir']}/#{new_resource.service_name}.pill") && ::File.symlink?("#{node['bluepill']['init_dir']}/#{new_resource.service_name}")
    @bp.enabled(true)
  else
    @bp.enabled(false)
  end
end

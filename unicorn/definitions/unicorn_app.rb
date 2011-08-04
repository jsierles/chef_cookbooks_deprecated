define :unicorn_app do
  include_recipe "unicorn"
  include_recipe "bluepill"

  config_path = "#{node[:unicorn][:config_path]}/#{params[:name]}"

  template config_path do
    cookbook 'unicorn'
    source "unicorn.pill.erb"
  end
  
  bluepill_service params[:name] do
    action [:enable, :load, :start]
  end
end
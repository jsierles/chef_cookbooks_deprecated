define :nagios_template, :template_type => "service" do
  node[:nagios][:templates][params[:template_type]][params[:name]] = params
end
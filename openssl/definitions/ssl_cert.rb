define :ssl_cert, :fqdn => "chef.example.com" do
  
  destdir = params[:name]
  fqdn = params[:fqdn]
  fqdn =~ /^(.+?)\.(.+)$/
  hostname = $1
  domain = $2
    
  directory destdir
  
  execute "generate SSL key" do
    command "cd #{destdir} && openssl genrsa 2048 > #{fqdn}.key && chmod 644 #{fqdn}.key"
    not_if { File.exists? "#{destdir}/#{fqdn}.key"}
  end
  
  template "/tmp/#{fqdn}.ssl-conf" do
    variables(:fqdn => params[:fqdn])
    cookbook "openssl"
    source "cert-request.txt.erb"
  end

  execute "generate SSL CRT" do
    command "cd #{destdir} && openssl req -config '/tmp/#{fqdn}.ssl-conf' -new -x509 -nodes -sha1 -days 3650 -key #{fqdn}.key > #{fqdn}.crt"
    not_if { File.exists? "#{destdir}/#{fqdn}.crt"}
  end
  
  execute "Generate SSL Info" do
    command "cd #{destdir} && openssl x509 -noout -fingerprint -text < #{fqdn}.crt > #{fqdn}.info"
    not_if { File.exists? "#{destdir}/#{fqdn}.info"}
  end

  execute "Generate SSL PEM" do
    command "cd #{destdir} && cat #{fqdn}.crt #{fqdn}.key > #{fqdn}.pem && chmod 644 #{fqdn}.pem"
    not_if { File.exists? "#{destdir}/#{fqdn}.pem"}
  end
  
end
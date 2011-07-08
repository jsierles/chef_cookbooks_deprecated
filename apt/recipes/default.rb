execute "apt-get-update" do
  command "apt-get update"
end

# run this to grab GPG keys for enabled ppas

cookbook_file "/usr/local/bin/launchpad-update" do
  source "launchpad-update.sh"
  mode 0755
end
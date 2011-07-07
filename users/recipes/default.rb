require_recipe 'ruby-shadow'

groups = search(:groups)

groups.each do |group|
  group group[:id] do
    group_name group[:id]
    gid group[:gid]
    action [ :create, :modify, :manage ]
  end

  if node[:active_groups].include?(group[:id])
    search(:users, "groups:#{group[:id]}").each do |user|
      home_dir = user[:home_dir] || "/home/#{user[:id]}"
      user user[:id] do
        comment user[:full_name]
        uid user[:uid]
        gid user[:groups].first
        home home_dir
        shell user[:shell] || "/bin/bash"
        password user[:password]
        supports :manage_home => false
        action [:create, :manage]
      end
      
      user[:groups].each do |g|
        group g do
          group_name g.to_s
          gid groups.find { |grp| grp[:id] == g }[:gid]
          members [user[:id]]
          append true
          action [ :create, :modify, :manage ]
        end
      end

      if (node[:users][:manage_files] || user[:local_files] == true)
        directory "#{home_dir}" do
          owner user[:id]
          group user[:groups].first.to_s
          mode 0700
          recursive true
        end

        directory "#{home_dir}/.ssh" do
          action :create
          owner user[:id]
          group user[:groups].first.to_s
          mode 0700
        end

        keys = Mash.new
        keys[user[:id]] = user[:ssh_key]

        if user[:ssh_key_groups]
          user[:ssh_key_groups].each do |group|
            users = search(:users, "groups:#{group}")
            users.each do |key_user|
              keys[key_user[:id]] = key_user[:ssh_key]
            end
          end
        end
      
        if user[:extra_ssh_keys]
          user[:extra_ssh_keys].each do |username|
            keys[username] = search(:users, "id:#{username}").first[:ssh_key]
          end
        end

        if user[:ssh_private_key]
          template "#{home_dir}/.ssh/id_rsa" do
            source "private_key.erb"
            action :create
            owner user[:id]
            group user[:groups].first.to_s
            variables(:key => user[:ssh_private_key])
            mode 0600
          end
        end
        
        template "#{home_dir}/.ssh/authorized_keys" do
          source "authorized_keys.erb"
          action :create
          owner user[:id]
          group user[:groups].first.to_s
          variables(:keys => keys)
          mode 0600
          not_if { user[:preserve_keys] }
        end
      else
        log "Not managing files for #{user[:id]} because home directory does not exist or this is not a management host." do
          level :debug
        end
      end
    end
  end
end

# Remove initial setup user and group.
user  "ubuntu" do
  action :remove
end

group "ubuntu" do
  action :remove
end

template "/root/.profile" do
  owner "root"
  group "root"
  mode "0600"
  source '.profile'
end


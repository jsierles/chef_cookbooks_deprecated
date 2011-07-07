default.apt[:mirror][:base_path] = "/u/mirrors/apt"

#default.apache[:sites][:dist][:server_name] = "dist.#{domain}"
default.apache[:sites][:dist][:server_alias] = "dist"
default.apache[:sites][:dist][:document_root] = "/u/mirrors/dist"
default.apache[:sites][:dist][:error_log] = "/var/log/apache2/dist_error.log"


default.solr[:root] = "/u/solr"
default.solr[:version] = "3.3.0"
default.solr[:war_file] = "apache-solr-#{node.solr[:version]}.war"
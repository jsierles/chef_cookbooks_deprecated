These Chef cookbooks assume the following:

* Ubuntu 10.04 (Lucid)
* Chef 0.10.x server and client
* No site-specific data such as IP addresses, users, etc.
* Usage as a submodule in another repository containing roles, data bags, etc.
* A minimal set of data bags containing: users, groups, certificates, apps and known ssh keys

== TODO

* LWRP or definition to simplify fetching and installing remote debian packages
* Script to generate a skeleton top-level repository with example roles, data bags and an encrypted data bag secret
* setup limits.conf for solr

== Attribution

These cookbooks are based on those developed at 37signals, partially available at: https://github.com/37signals/37s_cookbooks
Authors: John Williams, Mark Imbriaco, Taylor Weibley, Joshua Sierles and Will Jessop
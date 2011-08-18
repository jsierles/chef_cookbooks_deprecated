default.security[:limits][:global_soft][:user] = "*"
default.security[:limits][:global_soft][:type] = "soft"
default.security[:limits][:global_soft][:item] = "nofile"
default.security[:limits][:global_soft][:value] = 262144

default.security[:limits][:global_hard][:user] = "*"
default.security[:limits][:global_hard][:type] = "hard"
default.security[:limits][:global_hard][:item] = "nofile"
default.security[:limits][:global_hard][:value] = 262144
actions :create, :delete, :enable, :disable
 
attribute :name, :kind_of => String, :name_attribute => true
attribute :config_path, :kind_of => String
attribute :enabled, :default => true
attribute :exists, :default => false
attribute :variables, :kind_of => Hash


# set the default action

def initialize(*args)
  super
  @action = :create
end
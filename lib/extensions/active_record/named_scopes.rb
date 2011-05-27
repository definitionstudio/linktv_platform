class ActiveRecord::Base

  named_scope :offset, lambda {|offset| {:offset => offset}}
  named_scope :limit, lambda {|limit| {:limit => limit}}
  named_scope :order, lambda {|arg| {:order => arg}}
  named_scope :group, lambda {|arg| {:group => arg}}

end

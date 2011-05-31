class User < ActiveRecord::Base

  disable_deletes # Enforce use of destroy so callback are hit

  has_and_belongs_to_many :roles, :join_table => :roles_users, :foreign_key => 'user_id'

  has_many :video_play_stats

  # Check for bogus email address input. See
  # http://www.regular-expressions.info/email.html
  RE_EMAIL_NAME   = '[\w\.%\+\-]+'
  RE_DOMAIN_HEAD  = '(?:[A-Z0-9\-]+\.)+'
  RE_DOMAIN_TLD   = '(?:[A-Z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|jobs|museum)'
  RE_EMAIL_OK     = /\A#{RE_EMAIL_NAME}@#{RE_DOMAIN_HEAD}#{RE_DOMAIN_TLD}\z/i
  MSG_EMAIL_BAD   = "should look like an email address."

  validates_presence_of :login
  validates_uniqueness_of :login
  validates_uniqueness_of :email, :allow_nil => true
  validates_format_of :email, :with => RE_EMAIL_OK, :message => MSG_EMAIL_BAD, :unless => 'email.blank?'
  validates_presence_of :display_name
  validates_length_of :display_name, :in => 4..32
  
  validate :validate_permissions

  named_scope :live, :conditions => {:active => true, :deleted => false}

  # Only the following attributes are manageable via form submissions
  # :login is protected to prevent changing via form submissions
  attr_accessible :email, :display_name, :location, :password, :password_confirmation

  attr_accessor :current_password

  def validate_permissions
    invalid_roles = []

    # allowable_roles can be set by controller for currently logged in user,
    #  to restrict what roles can be modified.
    allowable_roles ||= self.roles
    
    allowable_role_ids = allowable_roles.collect{|r| r.id}
    self.roles.each do |role|
      next if allowable_role_ids.include? role.id
      invalid_roles << role
    end
    return if invalid_roles.empty?
    errors.add :roles,
      "contains values that the current user is not authorized to select (#{invalid_roles.collect{|r| r.name}.join(', ')})"
  end

  # When creating a new user, controller must indicate which roles are allowed to be created
  attr_accessor :allowable_roles

  def name
    display_name || "Login: #{login}"
  end

  def live?
    active && !deleted
  end

end



# == Schema Information
#
# Table name: users
#
#  id           :integer(4)      not null, primary key
#  display_name :string(255)     default("")
#  email        :string(255)
#  location     :string(255)
#  login        :string(255)
#  active       :boolean(1)      default(FALSE), not null
#  deleted      :boolean(1)      default(FALSE), not null
#  created_at   :datetime
#  updated_at   :datetime
#


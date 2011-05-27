class LinktvPlatformCreateRolesUsers < ActiveRecord::Migration
  def self.up
	  create_table "roles_users", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :id => false, :force => true do |t|
	    t.integer  "role_id",    :null => false
	    t.integer  "user_id",    :null => false
      t.timestamps
	  end

	  add_index "roles_users", ["role_id", "user_id"], :name => "index_roles_users_on_role_id_and_user_id", :unique => true
	  add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id"
	  add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"
  end

  def self.down
    drop_table :roles_user
  end
end

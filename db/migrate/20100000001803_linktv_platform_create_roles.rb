class LinktvPlatformCreateRoles < ActiveRecord::Migration
  def self.up
	  create_table "roles", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.string   "name",                           :null => false
	    t.text     "description"
	    t.boolean  "active",      :default => false, :null => false
	    t.boolean  "deleted",     :default => false, :null => false
      t.timestamps
	  end

	  add_index "roles", ["name"], :name => "index_roles_on_name", :unique => true
  end

  def self.down
    drop_table :roles
  end
end

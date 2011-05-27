class CreateAuthlogicUserFields < ActiveRecord::Migration
  def self.up
    add_column :users, :crypted_password, :string, :default => nil, :null => true
    add_column :users, :password_salt, :string, :default => nil, :null => true
    add_column :users, :persistence_token, :string, :default => nil, :null => true
    add_column :users, :single_access_token, :string, :default => nil, :null => true
    add_column :users, :perishable_token, :string, :default => nil, :null => true
  end

  def self.down
    remove_column :users, :crypted_password
    remove_column :users, :password_salt
    remove_column :users, :persistence_token
    remove_column :users, :single_access_token
    remove_column :users, :perishable_token
  end
end

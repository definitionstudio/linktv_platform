class SemanticApi < ActiveRecord::Base
  
  has_many :external_contents
  has_many :content_type_semantic_apis
  has_many :content_types, :through => :content_type_semantic_apis

  named_scope :live, :conditions => {:active => true, :deleted => false}

end

# == Schema Information
#
# Table name: semantic_apis
#
#  id           :integer(4)      not null, primary key
#  type         :string(255)
#  name         :string(255)
#  url          :string(1024)
#  query_params :string(1024)
#  quota_config :string(1024)
#  active       :boolean(1)      default(FALSE), not null
#  deleted      :boolean(1)      default(FALSE), not null
#  lifetime     :integer(4)
#  created_at   :datetime
#  updated_at   :datetime
#


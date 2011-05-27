class ContentTypeSemanticApi < ActiveRecord::Base
  belongs_to :semantic_api
  belongs_to :content_type
end


# == Schema Information
#
# Table name: content_type_semantic_apis
#
#  id              :integer(4)      not null, primary key
#  semantic_api_id :integer(4)
#  content_type_id :integer(4)
#  created_at      :datetime
#  updated_at      :datetime
#


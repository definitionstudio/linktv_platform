module Api::V1::RegionsHelper

  def region_api_response_object region, params = {}
    {
      :id => region.id,
      :name => region.name
    }
  end

end

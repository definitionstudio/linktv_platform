class Api::V1::RegionsController < Api::V1::ApiController

  def index
    @disable_paging = true
    @resources = Region.ordered
    respond do |resources|
      {:regions => resources.map{|r| @template.region_api_response_object(r, params)}}
    end

  end

  def show
    @resource = Region.find params[:id]
    respond do |resource|
      {:region => @template.region_api_response_object(resource, params)}
    end
  end
  
end

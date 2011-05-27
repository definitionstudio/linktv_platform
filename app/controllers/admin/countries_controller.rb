class Admin::CountriesController < Admin::AdminController

  def autocomplete
    if params['q'].nil? || params['q'].empty?
      render :nothing => true
      return
    end

    # TODO caching
    data = []
    records = Country.find(:all,
      :limit => 10,
      :order => 'name',
      :conditions => ['name LIKE ?', "%#{params['q']}%"])
    records.each do |record|
      data << {
        'id' => record.id,
        'label' => record.name
      }
    end

    result = {
      :status => 'success',
      :data => data
    }

    respond_to do |format|
      format.json {
        render :json => result
      }
    end

  end

end

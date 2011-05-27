class Admin::EntityIdentifiersController < Admin::AdminController

  def lookup
    @entity_identifier = EntityIdentifier.find_by_id params[:id]
    @entity_db = @entity_identifier.entity_db
    @entity_data = @entity_identifier.data

    unless @entity_data
      # Try a lookup
      @entity_data = @entity_identifier.lookup
    end

    unless @entity_data
      respond_to do |format|
        format.html {
          # Rendering as if passed, to allow popup to display something.
          render :text => 'Not found.'#, :status => :not_found
        }
        format.json {
          render :json => {:status => :not_found}#, :status => :not_found
        }
      end
      return
    end

    respond_to do |format|
      format.html {
        render :layout => false
      }
      format.json {
        render :json => @data
      }
    end

  end

  def lookup_by_uri
    @entity_db = EntityDb.entity_db_by_uri params[:uri]
    @entity_data = @entity_db.lookup_by_uri params[:uri]
    unless @entity_data
      render :text => 'Invalid URI', :status => :not_found
      return
    end

    respond_to do |format|
      format.html {
        render :partial => 'admin/entity_identifiers/lookup',
          :locals => {:entity_db => @entity_db, :entity_data => @entity_data}
      }
      format.json {
        render :json => @entity_data
      }
    end

  end

end

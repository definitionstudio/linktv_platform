class Admin::TopicsController < Admin::AdminController

  active_scaffold :topics do |config|
    config.actions = [:list, :search, :show, :create, :update, :subform, :delete]
    config.list.columns = [:name, :description, :entity_identifiers, :permalink, :live_video_segment_count, :active]
    config.search.columns = [:name]
    config.show.columns =
      [:name, :is_featured, :description, :entity_identifiers, :guid, :live_video_segment_count, :active]
    config.create.columns = config.update.columns =
      [:name, :description, :entity_identifiers, :active]

    config.columns[:description].options = {:html_options => {:rows => 3, :cols => 50}}
    config.columns[:active].form_ui = :checkbox
    config.columns[:deleted].form_ui = :checkbox

    config.action_links.add 'reset_permalink', :label => 'Reset Permalink', :type => :member, :position => false,
      :confirm => 'Reset topic permalink? This should only be used for correcting input errors, not for live topics.',
      :action => 'reset_permalink', :method => :post

    config.columns << :live_video_segment_count
    config.columns[:live_video_segment_count].label = 'Video segments'
  end

  alias :activescaffold_show :show
  alias :activescaffold_new :new
  alias :activescaffold_create :create
  alias :activescaffold_edit :edit
  alias :activescaffold_update :update
  
  include Admin::DeletedInactiveFilters

  def reset_permalink
    @record = Topic.find_by_id params[:id]
    @record.permalink = nil;
    @record.save

    # update Active Scaffold row (must set @record first)
    render :action => 'update_row'
  end

  def show
    unless (params[:tooltip] || nil)
      return activescaffold_show
    end

    if (params[:tooltip] || nil)
      topic = Topic.find_by_id params[:id]
      render :partial => 'tooltip', :locals => {:topic => topic}, :layout => false
    end
  end

  def new
    @active_scaffold = true
    @topic = Topic.new params[:topic]
    @entity_dbs = EntityDb.live
    @topic.fill_entity_identifiers

    # Within active scaffold
    @allow_existing_topics = false
    @record = @topic
    return activescaffold_new
  end

  def create
    @topic = Topic.new params[:topic]

    # Creating a new topic only - no topic_video_segments in this case
    @record = @topic # Active scaffold expects @record
    # See active_scaffold/actions/create.rb
    begin
      @record.save!
    rescue ActiveRecord::RecordInvalid
      # Assume it's a normal validation error
      @entity_dbs = EntityDb.live
    end
    # from active scaffold
    @insert_row = params[:parent_controller].nil?
    respond_to_action(:create)
  end

  def edit
    @topic = Topic.find params[:id]
    @entity_dbs = EntityDb.live
    @topic.fill_entity_identifiers

    # Within active scaffold
    @allow_existing_topics = false
    @record = @topic
    @using_active_scaffold = true
    return activescaffold_edit
  end

  def update
    @topic = Topic.find params[:id]

    # Check for entity identifiers being deleted
    params[:topic][:entity_identifiers_attributes].each do |key, ident_params|
      next unless ident_params[:id].present? && ident_params[:identifier].blank?
      ident_params[:'_destroy'] = true
    end  if params[:topic][:entity_identifiers_attributes].present?

    @topic.attributes = params[:topic]
    unless @topic.save
      # Assume it's a normal validation error
      @entity_dbs = EntityDb.live
    end
    
    @record = @topic
    respond_to_action(:update)
  end

  def matching
    @topics = Topic.matching_topics((params[:name] || nil), params[:omit_topics])
    respond_to do |format|
      format.json do
        render :json => {
          :status => 'success',
          :html => render_to_string(:partial => 'admin/topics/matching_topics',
            :locals => {:topics => @topics})
        }
      end
    end
  end

end

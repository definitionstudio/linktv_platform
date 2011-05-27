module TopicsHelper

  def topics_parameters current_params, args = {}
    params = {}
    unless current_params.nil? || current_params.empty?
      # Ensure args are keyed by symbols
      current_params.each{|k, v| params[k.to_sym] = v}
    end

    if args.include? :q
      if args[:q].nil?
        params.delete :q
      else
        params[:q] = args[:q]
      end
    end

    params[:index] = args[:index] if args[:index].present?

    # Allow nil to override
    if args.include? :page
      if args[:page].nil?
        params.delete :page
      else
        params[:page] = args[:page].to_i
      end
    end

    if args[:view].present?
      params[:view] = args[:view]
    elsif sticky_params[:view].present?
      params[:view] = sticky_params[:view]
    end

    if args[:order_by].present?
      params[:order_by] = args[:order_by]
    elsif args[:order_by] || nil
      params.delete :order_by
    end

    return nil if params.empty?
    query_params_string(params)
  end

  def parameterized_topics_path current_params, args = {}
		parameterized_topics_path_data(current_params, args)[:path]
	end

  def parameterized_topics_path_data current_params, args = {}
    params = topics_parameters(current_params, args)
    path = topics_path.dup
    path = [path, params].join('?') unless params.nil? || params.empty?
    {
			:path => path,
			:params => params
		}
  end
  
end

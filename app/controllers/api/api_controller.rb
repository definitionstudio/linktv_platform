class Api::ApiController < ApplicationController

  before_filter :check_access
  def check_access
    raise Exceptions::HTTPUnauthorized unless APP_CONFIG[:developers][:enable_api]
  end

  before_filter :set_defaults
  def set_defaults
    @disable_paging = false
    @page = (params[:page] || 1).to_i
    @page_size = (params[:page_size] || 16).to_i
    @sort = nil
  end

  protected
  def respond &block
    response = {
      :status => {
        :text => 'OK',
        :message => '',
        :response_time => Time.now.to_s(:rfc822)
      }
    }

    if @resources.present? && response[:status][:text] == 'OK'
      response[:sort] = @sort if @sort.present?

      unless @disable_paging

        if @resources.is_a? Sunspot::Search::StandardSearch
          response[:paging] = {
            :page => @page,
            :pages => (@resources.total / @page_size + 1).to_i,
            :page_size => @page_size,
            :total_items => @resources.total
          }
        else
          response[:paging] = {
            :page => @page,
            :pages => (@resources.length / @page_size + 1).to_i,
            :page_size => @page_size,
            :total_items => @resources.length
          }
        end
      end

      if @resources.is_a? Sunspot::Search::StandardSearch
        data = yield @resources.results
      else
        data = yield @resources.offset(@page_size * (@page - 1)).limit(@page_size)
      end

    elsif @resource.present?
      data = yield @resource
    end

    response.merge! data

    status = :ok
    respond_to do |format|
      format.json { render :json => response, :status => status }
      format.xml { render :xml => response.to_xml(:root => 'response', :dasherize => false), :status => status }
    end

  end

  def do_search klass, &block
    begin
      Sunspot.search klass do |query|
        yield query
        query.paginate(:page => @page, :per_page => @page_size)
      end
    rescue RSolr::RequestError
      raise Exceptions::HTTPBadRequest
    end
  end

  # handle exception responses
  rescue_from Exception do |exception|

    status = nil
    case exception
    when Exceptions::HTTPBadRequest
      status = :bad_request
    when Exceptions::HTTPUnauthorized, Exceptions::Unauthorized
      status = :unauthorized
    when Exceptions::HTTPNotFound, ActiveRecord::RecordNotFound
      status = :not_found
    when ActionController::InvalidAuthenticityToken
      status = :unauthorized
    else
      status = :internal_server_error
    end

    case status
    when :bad_request
      @error_name = 'Bad Request'
    when :unauthorized
      @error_name = 'Unauthorized'
    when :not_found
      @error_name = 'Not Found'
    else
      @error_name = 'Internal Server Error'
    end

    response = {
      :status => {
        :text => 'FAIL',
        :message => @error_name,
        :response_time => Time.now.to_s(:rfc822)
      }
    }
    respond_to do |format|
      format.json { render :json => response, :status => status }
      format.xml { render :xml => response.to_xml(:root => 'response', :dasherize => false), :status => status }
    end

  end

end

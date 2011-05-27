class FrontEndController < ApplicationController

  # Helpers that are mostly required everywhere
  helper :videos, :images

  before_filter :set_page_title
  def set_page_title
    @page_title = @template.site_name.dup
  end
  
  # handle exceptions
  rescue_from Exception do |exception|

    # @@benign_exceptions defined in Linktv::Platform::PlatformController
    unless @@benign_exceptions.include? exception.class
      logger.error "#{self.class.name} begin #{exception.inspect}"
      exception.backtrace.each do |err|
        logger.error err
      end
      logger.error "#{self.class.name} end #{exception.inspect}"
      @exception = exception
    end

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

    erase_render_results # In case something else was already rendered
    
    if request.xhr?
      respond_to do |format|
        format.json do
          render :json => {
            :status => 'error',
            :msg =>
              "An internal server error has prevented your operation from completing. " +
               "The issue has been reported to the site administrator. Please try your request again later.",
            :exception => DEVELOPMENT_MODE ? exception.inspect : nil
          }, :status => status
        end
      end
      return
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

    # respond to API request errors not handled by api_controller
    apimatch = request.path.match(/^\/api\//i)
    if !apimatch.nil?
      # API response
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
    else
      # standard error page
      render 'errors/error', :status => status
    end
    
  end

  def request_country
    return @request_country if @request_country.present?

    if DEVELOPMENT_MODE || request.env['SERVER_NAME'] == 'localhost'
      # For development testing, using www.google.com's IP
      ip = "74.125.19.147"
    else
      # Grab country based on IP
      ip = request.ip
    end

    country_id = (session[:country_id] || nil).to_i
    if country_id > 0
      @request_country = Country.find_by_id country_id
    else
      @request_country = GeoIpCache.lookup(ip)
    end

    # query GeoIP service
    if !@request_country.present?

      if Time.now.to_i < (session[:geoip_query_delay] || nil).to_i
        logger.info("*** skipping IP lookup (sleepy time) ***")
      else
        @request_country = GeoIpCache.query(ip)
        session[:geoip_query_delay] = Time.now.to_i + 30.seconds.to_i   # anti-flood
      end
    end

    if @request_country.present?
      session[:country_id] = @request_country.id
      session.delete :geoip_query_delay
    else
      session.delete :country_id
    end

    @request_country
  end
  
  before_filter :request_country # Ensure session variable is set
  helper_method :request_country


  begin
    # Check to see if any supplied params have been or should be saved
    def sticky_params
      session[:sticky_params] = {} unless (session[:sticky_params] || nil).is_a? Hash
      session[:sticky_params]
    end
    helper_method :sticky_params

    def sticky_params= val
      session[:sticky_params] = val
    end

    def check_for_sticky_params
      [:view].each do |key|
        if params[key].present?
          sticky_params[key] = params[key]
        elsif sticky_params[key].present?
          params[key] = sticky_params[key]
        end
      end
    end
  end

end

Spree::Api::BaseController.class_eval do
  before_filter :check_for_api_key
  before_filter :authenticate_user
  after_filter  :set_jsonp_format

  rescue_from Exception, :with => :error_during_processing
  rescue_from CanCan::AccessDenied, :with => :unauthorized
  rescue_from ActiveRecord::RecordNotFound, :with => :not_found

  def check_for_api_key
    render "spree/api/errors/must_specify_api_key", :status => 401 and return if api_key.blank?
  end

  def authenticate_user
    if api_key.present?
      unless @current_api_user = Spree.user_class.find_by_spree_api_key(api_key.to_s)
        render "spree/api/errors/invalid_api_key", :status => 401 and return
      end
    else
      # Effectively, an anonymous user
      @current_api_user = Spree.user_class.new
    end
  end

  def error_during_processing(exception)
    render :text => { :exception => exception.message }.to_json,
      :status => 422 and return
  end

  def api_key
    request.headers["X-Spree-Token"] || params[:token]
  end
  helper_method :api_key

end

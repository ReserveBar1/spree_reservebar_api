Spree::Api::BaseController.class_eval do

  #before_filter :check_for_api_key
  before_filter :authenticate_user

  rescue_from CanCan::AccessDenied, :with => :unauthorized
  rescue_from ActiveRecord::RecordNotFound, :with => :not_found

  helper Spree::Api::ApiHelpers

  def check_for_api_key
    render "spree/api/errors/must_specify_api_key", :status => 401 and return if api_key.blank?
  end

  def ensure_api_key
    if user = current_user
      if user.respond_to?(:spree_api_key) && user.spree_api_key.blank?
        user.generate_spree_api_key!
      end
    end
  end

  def authenticate_user
    if requires_authentication? || api_key.present?
      unless @current_api_user = Spree::User.find_by_spree_api_key(api_key.to_s)
        render "spree/api/errors/invalid_api_key", :status => 401 and return
      end
    else
      # Effectively, an anonymous user
      @current_api_user = Spree::User.new
    end
  end

  def current_api_user
    @current_api_user ||= nil
  end

  def error_during_processing(exception)
    render :text => { :exception => exception.message }.to_json,
      :status => 422 and return
  end

  def api_key
    request.headers["X-Spree-Token"] || params[:token]
  end
  helper_method :api_key

  def requires_authentication?
    false
    #true
    #Spree::Api::Config[:requires_authentication]
  end

  def unauthorized
    render "spree/api/errors/unauthorized", :status => 401
  end

  def map_nested_attributes_keys(klass, attributes)
    nested_keys = klass.nested_attributes_options.keys
    attributes.inject({}) do |h, (k,v)|
      key = nested_keys.include?(k.to_sym) ? "#{k}_attributes" : k
      h[key] = v
      h
    end.with_indifferent_access
  end

  def model_class
    "Spree::#{controller_name.classify}".constantize
  end

  private

  def check_http_authorization
    if request.headers['HTTP_AUTHORIZATION'].blank?
      render "spree/api/errors/unauthorized", :status => 401
    end
  end

  def load_resource
    if member_action?
      @object ||= load_resource_instance
      instance_variable_set("@#{object_name}", @object)
    else
      @collection ||= collection
      instance_variable_set("@#{controller_name}", @collection)
    end
  end

  def load_resource_instance
    if new_actions.include?(params[:action].to_sym)
      build_resource
    elsif params[:id]
      find_resource
    end
  end

  def build_resource
    if parent.present?
      parent.send(controller_name).build(params[object_name])
    else
      if model_class == Spree::Order
        return
      else
        model_class.new(params[object_name])
      end
    end
  end
end

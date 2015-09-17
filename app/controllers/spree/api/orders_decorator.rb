
Spree::Api::OrdersController.class_eval do
  include SslRequirement

  respond_to :json

  ssl_allowed
  skip_before_filter :access_denied
  skip_before_filter :check_http_authorization
  skip_before_filter :load_resource
  before_filter :authorize_read!, :except => [:index, :search, :create]

  before_filter :check_bottle_number_limit, :only => [:create]


  def show
    render file: 'spree/api/orders/show.rabl'
  end

  def create
    nested_params[:line_items_attributes] = sanitize_line_items(nested_params[:line_items_attributes])
    @order = Spree::Order.build_from_api(current_api_user, nested_params)
    #render file: 'spree/api/orders/create'
    render :json => response_hash.to_json, :status => 201
  end


  private

  def nested_params
    @nested_params ||= map_nested_attributes_keys(Spree::Order, params[:order] || {})
  end

  def sanitize_line_items(line_item_attributes)
    return {} if line_item_attributes.blank?
    line_item_attributes = line_item_attributes.map do |id, attributes|
      attributes ||= id
      [id, attributes.slice(*Spree::LineItem.attr_accessible[:api])]
    end
    line_item_attributes = Hash[line_item_attributes].delete_if { |k,v| v.empty? }
  end

  def order
    @order ||= Spree::Order.find_by_number!(params[:id])
  end

  def next!(options={})
    if @order.valid? && @order.next
      render :show, :status => options[:status] || 200
    else
      render :could_not_transition, :status => 422
    end
  end

  def authorize_read!
    if order.user != current_api_user
      raise CanCan::AccessDenied
    end
  end

  def response_hash
    rh = {order: { token: order.token, line_items: [] } }
    rh =  order.attributes.keys.each_with_object(rh) do |k|
      rh[:order][k] = order.attributes[k]
      rh
    end
    order.line_items.each_with_object(rh) do |li|
      rh[:order][:line_items] << { quantity: li.quantity, price: li.price, variant: {name: li.variant.name}}
      rh
    end
  end

  def check_bottle_number_limit
    if bottle_quantity > 12
      render :text => { :exception => 'Cannot order more than 12 bottles'}.to_json, :status => 404
    end
    if ardbeg_quantity > 1
      render :text => { :exception => 'Cannot order more than 1 bottle of Ardbeg Supernova'}.to_json,
             :status => 404
    end
  end

  def bottle_quantity
    return 0 unless params[:order] && params[:order][:line_items]
    params[:order][:line_items].sum do |index, attributes|
      attributes['quantity'].to_i
    end
  end

  def ardbeg_quantity
    ardbeg = Spree::Product.find_by_permalink('ardbeg-supernova-2015')
    return 0 unless ardbeg
    params[:order][:line_items].sum do |index, attributes|
      attributes['sku'] == ardbeg.sku ? attributes['quantity'].to_i : 0
    end
  end
end

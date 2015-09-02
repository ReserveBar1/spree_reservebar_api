
Spree::Api::OrdersController.class_eval do
  respond_to :json

  skip_before_filter :access_denied
  skip_before_filter :check_http_authorization
  skip_before_filter :load_resource
  before_filter :authorize_read!, :except => [:index, :search, :create]

  def index
    raise CanCan::AccessDenied unless current_api_user.has_role?("admin")
    @orders = Order.ransack(params[:q]).result.page(params[:page]).per(params[:per_page])
    respond_with(@orders)
  end

  def show
    render file: 'spree/api/orders/show.rabl'
  end

  def create
    nested_params[:line_items_attributes] = sanitize_line_items(nested_params[:line_items_attributes])
    @order = Spree::Order.build_from_api(current_api_user, nested_params)
    #render file: 'spree/api/orders/create'
    render :json => response_hash.to_json
  end

  def update
    authorize! :update, Spree::Order
    nested_params[:line_items_attributes] = sanitize_line_items(nested_params[:line_items_attributes])
    if order.update_attributes(nested_params)
      order.update!
      respond_with(order, :default_template => :show)
    else
      invalid_resource!(order)
    end
  end

  def cancel
    order.cancel!
    render :show
  end

  def empty
    order.line_items.destroy_all
    order.update!
    render :text => nil, :status => 200
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
end

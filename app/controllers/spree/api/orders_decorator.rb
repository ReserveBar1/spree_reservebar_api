
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
    respond_with(order)
  end

  def create
    nested_params[:line_items_attributes] = sanitize_line_items(nested_params[:line_items_attributes])
    @order = Spree::Order.build_from_api(current_api_user, nested_params)
    respond_with(@order, :status => 201 )
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
    @order ||= Order.find_by_number!(params[:id])
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
end

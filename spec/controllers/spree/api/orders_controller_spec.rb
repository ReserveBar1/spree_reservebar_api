require 'spec_helper'

module Spree
  describe Api::OrdersController do
    render_views

    let!(:order) { Factory(:order) }
    let(:attributes) { [:number, :item_total, :total,
                        :state, :adjustment_total,
                        :user_id, :created_at, :updated_at,
                        :completed_at, :payment_total, :shipment_state,
                        :payment_state, :email, :special_instructions] }

    let(:actual_attributes) { [:adjustment_total, :bill_address_id, :completed_at,
                               :created_at, :credit_total, :email, :id, :item_total,
                               :number, :payment_state, :payment_total, :ship_address_id,
                               :shipment_state, :shipping_method_id, :special_instructions,
                               :state, :total, :updated_at, :user_id]}

     let(:variant) { Factory(:variant) }

      before { stub_authentication! }
      let(:user) { mock_model(Spree::User, :has_role? => true) }
      before { controller.stub :current_user => user }



    it "can view their own order" do
      controller.stub :current_api_user => order.user
      api_get :show, :id => order.to_param
      response.status.should == 200
      json_response['order']['id'].should eq order.id
    end

    it "can not view someone else's order" do
      Order.any_instance.stub :user => stub_model(Spree::User)
      api_get :show, :id => order.to_param
      assert_unauthorized!
    end

    it 'can retry a checkout step after an error' do
      pending ''
    end

    it "can create an order" do
      variant = Factory(:variant)
      # api uses sku instead of id
      api_post :create, :order => { :line_items => { "0" => { :variant_id => variant.sku, :quantity => 5 } } }
      response.status.should == 201
      order = Order.last
      order.line_items.count.should == 1
      order.line_items.first.variant.should == variant
      order.line_items.first.quantity.should == 5
      json_response['order']['state'].should == 'cart'
    end

    it 'cannot create an order with more than 12 bottles' do
      variant = Factory(:variant)
      # api uses sku instead of id
      api_post :create, :order => { :line_items => { "0" => { :variant_id => variant.sku, :quantity => 13 } } }
      response.status.should == 404
      json_response['error'].should == 'Cannot order more than 12 bottles'
    end
  end
end

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


    it "cannot view all orders" do
      api_get :index
      assert_unauthorized!
    end

    it "can view their own order" do
      Order.any_instance.stub :user => current_api_user
      api_get :show, :id => order.to_param
      response.status.should == 200
      json_response['order'].should have_attributes(actual_attributes)
    end

    it "can not view someone else's order" do
      Order.any_instance.stub :user => stub_model(Spree::User)
      api_get :show, :id => order.to_param
      assert_unauthorized!
    end

    it "cannot cancel an order that doesn't belong to them" do
      order.update_attribute(:completed_at, Time.now)
      order.update_attribute(:shipment_state, "ready")
      api_put :cancel, :id => order.to_param
      assert_unauthorized!
    end


    it "cannot add address information to an order that doesn't belong to them" do
      api_put :address, :id => order.to_param
      assert_unauthorized!
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

    it "can create an order without any parameters" do
      lambda { api_post :create }.should_not raise_error(NoMethodError)
      response.status.should == 201
      order = Order.last
      json_response["state"].should == "cart"
    end

    it "cannot create an order with an abitrary price for the line item" do
      variant = Factory(:variant)
      api_post :create, :order => {
        :line_items => {
          "0" => {
            :variant_id => variant.to_param,
            :quantity => 5,
            :price => 0.44
          }
        }
      }
      response.status.should == 201
      order = Order.last
      order.line_items.count.should == 1
      order.line_items.first.variant.should == variant
      order.line_items.first.quantity.should == 5
      order.line_items.first.price.should == order.line_items.first.variant.price
    end

    context "working with an order" do
      before do
        Order.any_instance.stub :user => current_api_user
        create(:payment_method)
        order.next # Switch from cart to address
        order.ship_address.should be_nil
        order.state.should == "address"
      end

 
      def clean_address(address)
        address.delete(:state)
        address.delete(:country)
        address
      end

      let(:address_params) { { :country_id => Country.first.id, :state_id => State.first.id } }
      let(:billing_address) { { :firstname => "Tiago", :lastname => "Motta", :address1 => "Av Paulista",
                                :city => "Sao Paulo", :zipcode => "1234567", :phone => "12345678",
                                :country_id => Country.first.id, :state_id => State.first.id} }
      let(:shipping_address) { { :firstname => "Tiago", :lastname => "Motta", :address1 => "Av Paulista",
                                 :city => "Sao Paulo", :zipcode => "1234567", :phone => "12345678",
                                 :country_id => Country.first.id, :state_id => State.first.id} }
      let!(:shipping_method) { create(:shipping_method) }
      let!(:payment_method) { create(:payment_method) }

      it "can not update line item prices" do
        order.line_items << create(:line_item)
        api_put :update,
          :id => order.to_param,
          :order => {
            :line_items => {
              order.line_items.first.id =>
              {
                :variant_id => create(:variant).id,
                :quantity => 2,
                :price => 0.44
              }
            }
          }

        response.status.should == 200
        json_response['item_total'].to_f.should_not == order.item_total.to_f
      end


      it "can add billing address" do
        order.bill_address.should be_nil

        api_put :update, :id => order.to_param, :order => { :bill_address_attributes => billing_address }

        order.reload.bill_address.should_not be_nil
      end

      it "receives error message if trying to add billing address with errors" do
        order.bill_address.should be_nil
        billing_address[:firstname] = ""

        api_put :update, :id => order.to_param, :order => { :bill_address_attributes => billing_address }

        json_response['error'].should_not be_nil
        json_response['errors'].should_not be_nil
        json_response['errors']['bill_address.firstname'].first.should eq "can't be blank"
      end

      it "can add shipping address" do
        order.ship_address.should be_nil

        api_put :update, :id => order.to_param, :order => { :ship_address_attributes => shipping_address }

        order.reload.ship_address.should_not be_nil
      end

      it "receives error message if trying to add shipping address with errors" do
        order.ship_address.should be_nil
        shipping_address[:firstname] = ""

        api_put :update, :id => order.to_param, :order => { :ship_address_attributes => shipping_address }

        json_response['error'].should_not be_nil
        json_response['errors'].should_not be_nil
        json_response['errors']['ship_address.firstname'].first.should eq "can't be blank"
      end

      context "with a line item" do
        before do
          order.line_items << create(:line_item)
        end


        it "can empty an order" do
          api_put :empty, :id => order.to_param
          response.status.should == 200
          order.reload.line_items.should be_empty
        end

        it "can list its line items with images" do
          order.line_items.first.variant.images.create!(:attachment => image("thinking-cat.jpg"))

          api_get :show, :id => order.to_param

          json_response['line_items'].first['variant'].should have_attributes([:images])
        end

        it "lists variants product id" do
          api_get :show, :id => order.to_param

          json_response['line_items'].first['variant'].should have_attributes([:product_id])
        end
      end
    end
  end
end

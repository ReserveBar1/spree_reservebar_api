require 'spec_helper'

module Spree
  describe Api::CheckoutsController do
    render_views

    before(:each) do
      stub_authentication!
      Spree::Config[:track_inventory_levels] = false
      country_zone = Factory(:zone, :name => 'CountryZone')
      @state = Factory(:state)
      @country = @state.country
      country_zone.members.create(:zoneable => @country)

      @shipping_method = Factory(:shipping_method, :zone => country_zone)
      @payment_method = Factory(:payment_method)
    end

    let(:user) { mock_model(Spree::User, :has_role? => true) }
    before { controller.stub :current_user => user }

    after do
      Spree::Config[:track_inventory_levels] = true
    end

    context "POST 'create'" do
      it "creates a new order when no parameters are passed" do
        api_post :create

        json_response['order']['number'].should be_present
        response.status.should == 201
      end

      it "should not have a user by default" do
        api_post :create

        json_response['user_id'].should_not be_present
        response.status.should == 201
      end

      it "should not have an email by default" do
        api_post :create

        json_response['email'].should_not be_present
        response.status.should == 201
      end
    end

    context "PUT 'update'" do
      let(:order) { Factory(:order) }

      before(:each) do
        Order.any_instance.stub(:confirmation_required? => true)
        Order.any_instance.stub(:payment_required? => true)
      end

      it "will return an error if the recently created order cannot transition from cart to address" do
        order.state.should eq "cart"
        order.email = nil # email is necessary to transition from cart to address
        order.save!

        api_put :update, :id => order.to_param, :order_token => order.token

        json_response['email'][0].should =~ /can\'t be blank/
        response.status.should == 422
      end

      it "should transition a recently created order from cart do address" do
        order.state.should eq "cart"
        order.email.should_not be_nil
        api_put :update,  :id => order.to_param, :order_token => order.token
        order.reload.state.should eq "address"
      end

      it "will return an error if the order cannot transition" do
        order.update_column(:state, "address")
        api_put :update, :id => order.to_param, :order_token => order.token
        json_response['ship_address.firstname'][0].should =~ /can\'t be blank/
        response.status.should == 422
      end

      it "can update addresses and transition from address to delivery" do
        order.update_column(:state, "address")
        shipping_address = billing_address = {
          :firstname  => 'John',
          :lastname   => 'Doe',
          :address1   => '7735 Old Georgetown Road',
          :city       => 'Bethesda',
          :phone      => '3014445002',
          :zipcode    => '20814',
          :state_id   => @state.id,
          :country_id => @country.id
        }
        api_put :update,
                :id => order.to_param, :order_token => order.token,
                :order => { :bill_address_attributes => billing_address, :ship_address_attributes => shipping_address }

        json_response['order']['state'].should == 'delivery'
        json_response['order']['bill_address']['firstname'].should == 'John'
        json_response['order']['ship_address']['firstname'].should == 'John'
        response.status.should == 200
      end

      it "can update shipping method and transition from delivery to payment" do
        order.update_column(:state, "delivery")
        api_put :update, :id => order.to_param, :order_token => order.token,
                         :order => { :shipping_method_id => @shipping_method.id }

        json_response['order']['shipments'][0]['shipping_method']['name'].should == @shipping_method.name
        json_response['order']['state'].should == 'payment'
        response.status.should == 200
      end

      it "can update payment method and transition from payment to complete" do
        order.update_column(:state, "payment")
        api_put :update, :id => order.to_param, :order_token => order.token,
                         :order => { :payments_attributes => [{ :payment_method_id => @payment_method.id }] }
        json_response['order']['state'].should == 'complete'
        json_response['order']['payments'][0]['payment']['payment_method']['name'].should == @payment_method.name
        response.status.should == 200
      end

      it "returns the order if the order is already complete" do
        order.update_column(:state, "complete")
        api_put :update, :id => order.to_param, :order_token => order.token
        json_response['order']['number'].should == order.number
        response.status.should == 200
      end

      it "can assign a user to the order" do
        user = create(:user)
        api_put :update, :id => order.to_param, :order_token => order.token, :order => { :user_id => user.id }
        json_response['user_id'].should == user.id
        response.status.should == 200
      end

      it "can assign an email to the order" do
        api_put :update, :id => order.to_param, :order_token => order.token, :order => { :email => "guest@spreecommerce.com" }
        json_response['order']['email'].should == "guest@spreecommerce.com"
        response.status.should == 200
      end

      it "cannot update an order without authorization" do
        api_put :update, :id => order.to_param
        assert_unauthorized!
      end
    end
  end
end

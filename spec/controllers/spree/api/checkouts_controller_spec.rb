require 'spec_helper'

describe Spree::Api::CheckoutsController do
  render_views

  before(:each) do
    stub_authentication!
    Spree::Config[:tax_using_retailer_address] = false
    country_zone = Factory(:zone, name: 'CountryZone')
    @state = Factory(:state, abbr: 'NY')
    @country = @state.country
    country_zone.members.create(zoneable: @country)

    @shipping_method = Factory(:shipping_method, zone: country_zone)
    @payment_method = Factory(:payment_method)

    @retailer = Spree::Retailer.create(name: 'first retailer', payment_method: @payment_method,
                                       phone: '1234567890', email: 'test@test.com')
    @product = Factory(:product)
    @variant = Factory(:variant, product: @product)
    @line_item = Factory(:line_item, variant: @variant, variant_id: @variant.id, quantity: 1)
  end

  let(:user) { Factory(:user) }
  before { controller.stub current_user: user }

  after do
    Spree::Config[:track_inventory_levels] = true
  end

  context "PUT 'update'" do
    let(:order) { Factory(:order) }

    before(:each) do
      Spree::Order.any_instance.stub(confirmation_required?: true)
      Spree::Order.any_instance.stub(payment_required?: true)
      Spree::Order.any_instance.stub(line_items: [@line_item])
    end

    # Broken - email gets added back (wrong email)
    it 'will return an error if the order cannot transition from cart to address' do
      order.state.should eq 'cart'
      order.email = nil # email is necessary to transition from cart to address
      order.save!

      api_put :update, id: order.to_param, order_token: order.token

      # json_response['email'][0].should =~ /can\'t be blank/
      json_response['error'].should eq 'Could not transition order state'
      response.status.should == 422
    end

    it 'should transition a recently created order from cart do address' do
      order.state.should eq 'cart'
      order.email.should_not be_nil
      api_put :update, id: order.to_param, order_token: order.token
      order.reload.state.should eq 'address'
    end

    it 'will return an error if the order cannot transition' do
      order.update_column(:state, 'address')
      api_put :update, id: order.to_param, order_token: order.token
      # json_response['ship_address.firstname'][0].should =~ /can\'t be blank/
      json_response['error'].should eq 'Could not transition order state'
      response.status.should == 400
    end

    it 'can update addresses and transition from address to delivery' do
      Spree::Product.any_instance.stub(:state_blacklist).and_return('AL')
      order.update_column(:state, 'address')
      shipping_address = {
        firstname:  'John',
        lastname:   'Doe',
        address1:   '7735 Old Georgetown Road',
        city:       'Bethesda',
        phone:      '3014445002',
        zipcode:    '20814',
        state_id:   @state.id,
        country_id: @country.id
      }
      api_put :update,
              id: order.to_param, order_token: order.token,
              order: { ship_address_attributes: shipping_address, is_legal_age: true }

      json_response['order']['state'].should eq 'delivery'
      json_response['order']['ship_address']['firstname'].should eq 'John'
      response.status.should == 200
    end

    it 'can update shipping method and transition from delivery to payment' do
      order.update_column(:state, 'delivery')
      api_put :update, id: order.to_param, order_token: order.token,
                       order: { shipping_method_id: @shipping_method.id }

      json_response['order']['shipping_method_id'].should eq @shipping_method.id
      json_response['order']['state'].should eq 'payment'
      response.status.should == 200
    end

    it 'can update payment method and transition from payment to complete' do
      pending 'credit card setup for specs'
      order.update_column(:state, 'payment')
      bill_address = {
        firstname:  'John',
        lastname:   'Doe',
        address1:   '7735 Old Georgetown Road',
        city:       'Bethesda',
        phone:      '3014445002',
        zipcode:    '20814',
        state_id:   @state.id,
        country_id: @country.id
      }
      api_put :update, id: order.to_param, order_token: order.token,
                       bill_address: bill_address, has_accepted_terms: true,
                       order: { payments_attributes: [{ payment_method_id: @payment_method.id }] }
      json_response['order']['state'].should eq 'complete'
      json_response['order']['payment_method_id'].should eq @payment_method.name
      response.status.should == 200
    end

    it 'returns error in json format when update payment method fails' do
      order.update_column(:state, 'payment')
      bill_address = {
        firstname:  'John',
        lastname:   'Doe',
        address1:   '7735 Old Georgetown Road',
        city:       'Bethesda',
        phone:      '3014445002',
        zipcode:    '20814',
        state_id:   @state.id,
        country_id: @country.id
      }
      api_put :update, id: order.to_param, order_token: order.token, has_accepted_terms: true,
                       order: { payments_attributes: [{ payment_method_id: @payment_method.id }] }
      json_response['error'].should eq 'Billing Address is required'
      response.status.should == 400
    end

    it 'can not transition to delivery unless all items in order are valid for shipping state' do
      Spree::Product.any_instance.stub(:state_blacklist).and_return('AL, NY, TX')
      order.update_column(:state, 'address')
      shipping_address = {
        firstname:  'John',
        lastname:   'Doe',
        address1:   '7735 Old Georgetown Road',
        city:       'Bethesda',
        phone:      '3014445002',
        zipcode:    '20814',
        state_id:   @state.id,
        country_id: @country.id
      }
      billing_address = shipping_address
      api_put :update,
              id: order.to_param, order_token: order.token,
              order: { ship_address_attributes: shipping_address, is_legal_age: true },
              billing_address: billing_address

      json_response['error'].should eq "Unable to ship all selected products to #{@state.abbr}"
      response.status.should == 400
    end

    it 'returns the order if the order is already complete' do
      order.update_column(:state, 'complete')
      api_put :update, id: order.to_param, order_token: order.token
      json_response['order']['number'].should eq order.number
      response.status.should == 200
    end

    it 'can assign an email to the order' do
      api_put :update, id: order.to_param, order_token: order.token,
                       order: { email: 'guest@spreecommerce.com' }
      json_response['order']['email'].should eq 'guest@spreecommerce.com'
      response.status.should == 200
    end

    it 'cannot update an order without authorization' do
      api_put :update, id: order.to_param
      assert_unauthorized!
    end
  end
end

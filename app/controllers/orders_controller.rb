class OrdersController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :paypal_init, :except => [:index]
  
  def index; end

  def create_order
    price = '100.00'
    request = PayPalCheckoutSdk::Orders::OrdersCreateRequest::new
    request.request_body({
      :intent => 'CAPTURE',
      :purchase_units => [
        {
          :amount => {
            :currency_code => 'USD',
            :value => price
          }
        }
      ]
    })
    begin
      response = @client.execute request
      order = Order.new
      order.price = price.to_i
      order.token = response.result.id
      if order.save
        return render :json => {:token => response.result.id}, :status => :ok
      end
    rescue PayPalHttp::HttpError => ioe
      # HANDLE THE ERROR
      puts ioe.status_code
      puts ioe.headers["debug_id"]
    end
  end

  def capture_order
    request = PayPalCheckoutSdk::Orders::OrdersCaptureRequest::new params[:order_id]
    begin
      response = @client.execute request
      order = Order.find_by :token => params[:order_id]
      order.paid = response.result.status == 'COMPLETED'
      if order.save
        return render :json => {:status => response.result.status}, :status => :ok
      end
    rescue PayPalHttp::HttpError => ioe
      # Something went wrong server-side
      puts ioe.status_code
      puts ioe.headers["paypal-debug-id"]
    end
  end

  private
  def paypal_init
    client_id = 'Adt6pOC1P3WWkdqz0EHIu3mnLJdm7Cbo2Eli-CG0kfLXSbU-5PkL3QwiwASQjR61IJMUHlUi4WS5kOAw'
    client_secret = 'EEYaMAV1HcAsPZ2gRzQVZ86kUpf3YmcvrFqtcuB1QVrHbpmQbI-4nZ0a7uB6_tzYdFri6hunGA42-4aN'
    environment = PayPal::SandboxEnvironment.new client_id, client_secret
    @client = PayPal::PayPalHttpClient.new environment
  end
end

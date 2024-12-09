require 'stripe'
require 'json'

Stripe.api_key = ENV['STRIPE_API_KEY']

Handler = Proc.new do |request, response|
  response['Content-Type'] = 'application/json'

  begin
    request_body = JSON.parse(request.body)

    session = Stripe::Checkout::Session.create(
      line_items: [{
        price: ENV['STRIPE_PRICE_ID'],
        quantity: 1
      }],
      mode: 'payment',
      success_url: "#{ENV['DOMAIN']}/success",
      cancel_url: "#{ENV['DOMAIN']}/",
      automatic_tax: { enabled: true },
      allow_promotion_codes: true,
      metadata: {
        name: request_body['name'],
        accessibility_needs: request_body['a11y'],
        dietary_restrictions: request_body['allergy']
      }
    )

    puts "Session created: #{session.id}"
  
    response.status = 200
    response.body = JSON.generate({
      url: session.url,
      sessionId: session.id 
    })

  rescue => e
    puts "Error: #{e.class} - #{e.message}" 
    puts e.backtrace.join("\n")

    response.status = 500
    response.body = JSON.generate({
      error: e.message,
      errorType: e.class.to_s
    })
  end
end

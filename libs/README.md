A sample code for calling Amazon Pay API version 2 in Ruby.
See: http://amazonpaycheckoutintegrationguide.s3.amazonaws.com/amazon-pay-checkout/introduction.html

# Requires
Ruby version: 2.3.0 or higher
Note: For less than 2.5.0, you have to update the gem of openssl by following the instructions below:
    https://github.com/ruby/openssl

# How to use
At first, instantiate AmazonPayClient like below:

```ruby
    client = AmazonPayClient.new {
        public_key_id: 'XXXXXXXXXXXXXXXXXXXXXXXX', # the publick key ID you obtained at seller central
        private_key: File.read('./privateKey.pem'), # the private key you obtained at seller central
        region: 'jp', # you can specify 'na', 'eu' or 'jp'.
        sandbox: true
    }
```

## To generate button signature
Invoke 'generate_button_signature' specifying the parameters below:
 - payload: the request payload of the API. You can specify either JSON string or Hash instance.
See: http://amazonpaycheckoutintegrationguide.s3.amazonaws.com/amazon-pay-checkout/add-the-amazon-pay-button.html#3-sign-the-payload

Example:

```ruby
    signature = client.generate_button_signature {
        webCheckoutDetails: {
            checkoutReviewReturnUrl: 'http://example.com/review'
        },
        storeId: 'amzn1.application-oa2-client.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
    }
```

## Others

Invoke 'api_call' method specifying the parameters below:
 - url_fragment: the last part of the URL of the API. ex) 'checkoutSessions' if the URL is 'https://pay-api.amazon.com/:environment/:version/checkoutSessions/'
 - method: the HTTP method of the API.
 - (Optional) payload: the request payload of the API. You can specify either JSON string or Hash instance.
 - (Optional) headers: the HTTP headers of the API. ex) {header1: 'value1', header2: 'value2'}
 - (Optional) query_params: the query parameters of the API. ex) {param1: 'value1', param2: 'value2'}

Then, the response of the API call is returned.

Example 1: Create Checkout Session (http://amazonpaycheckoutintegrationguide.s3.amazonaws.com/amazon-pay-api-v2/checkout-session.html#create-checkout-session)

```ruby
    response = client.api_call ("checkoutSessions", "POST",
        payload: {
            webCheckoutDetails: {
                checkoutReviewReturnUrl: "https://example.com/review"
            },
            storeId: "amzn1.application-oa2-client.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        },
        headers: {'x-amz-pay-idempotency-key': SecureRandom.hex(10)}
    )
```

Example 2: Get Checkout Session (http://amazonpaycheckoutintegrationguide.s3.amazonaws.com/amazon-pay-api-v2/checkout-session.html#get-checkout-session)

```ruby
    response = client.api_call ("checkoutSessions/#{amazon_checkout_session_id}", 'GET')
```
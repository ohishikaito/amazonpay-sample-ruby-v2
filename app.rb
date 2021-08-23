require './keys/keyinfo'
require './libs/signature'

require 'sinatra'
require 'json'
require 'securerandom'

config = {
    region: 'jp',
    public_key_id: KeyInfo::PUBLIC_KEY_ID,
    private_key: File.read('./keys/privateKey.pem'),
    sandbox: true
}

client = AmazonPayClient.new(config)

get '/' do
  redirect '/cart'
end


deliverySpecifications = {
    addressRestrictions: {
        type: "Allowed",
        restrictions: {
            JP: {
                statesOrRegions: [
                    "北海道",
                    "青森県",
                    "岩手県",
                    "宮城県",
                    "秋田県",
                    "山形県",
                    "福島県",
                    "茨城県",
                    "栃木県",
                    "群馬県",
                    "埼玉県",
                    "千葉県",
                    "東京都",
                    "神奈川県",
                    "新潟県",
                    "富山県",
                    "石川県",
                    "福井県",
                    "山梨県",
                    "長野県",
                    "岐阜県",
                    "静岡県",
                    "愛知県",
                    "三重県",
                    "滋賀県",
                    "京都府",
                    "大阪府",
                    "兵庫県",
                    "奈良県",
                    "和歌山県",
                    "鳥取県",
                    "島根県",
                    "岡山県",
                    "広島県",
                    "山口県",
                    "徳島県",
                    "香川県",
                    "愛媛県",
                    "高知県",
                    "福岡県",
                    "佐賀県",
                    "長崎県",
                    "熊本県",
                    "大分県",
                    "宮崎県",
                    "鹿児島県",
                    "沖縄県"
                ]
            }
        }
    }
}

get '/cart' do
    payload = JSON.generate({
        webCheckoutDetails: {
            checkoutReviewReturnUrl: 'http://localhost:4567/review'
        },
        # 指定した都道府県しか入力できないようにする。maker遠方対応のため
        deliverySpecifications: deliverySpecifications,
        storeId: KeyInfo::STORE_ID
    })
    erb :cart, locals: {
        merchant_id: KeyInfo::MERCHANT_ID,
        payload: payload,
        signature: client.generate_button_signature(payload), # Sign the payload
        public_key_id: KeyInfo::PUBLIC_KEY_ID
    }
end

get '/review' do
    # Get Checkout Session
    response = client.api_call("checkoutSessions/#{params['amazonCheckoutSessionId']}", 'GET')
    if response.code.to_i == 201 || response.code.to_i == 200
        erb :review, locals: JSON.parse(response.body)
    else
        erb :error, locals: {status: response.code.to_i, body: response.body}
    end
end

post '/auth' do
    # Update Checkout Session
    response = client.api_call("checkoutSessions/#{params['amazonCheckoutSessionId']}", 'PATCH',
        payload: {
            webCheckoutDetails: {
                checkoutResultReturnUrl: 'http://localhost:4567/thanks'
            },
            paymentDetails: {
                paymentIntent: 'AuthorizeWithCapture',
                # paymentIntent: 'Authorize',
                # paymentIntent: 'Confirm',
                canHandlePendingAuthorization: false,
                chargeAmount: {
                    amount: '29980',
                    currencyCode: "JPY"
                }
            },
            merchantMetadata: {
                merchantReferenceId: "MY-ORDER-100",
                merchantStoreName: "Test Store",
                noteToBuyer: "Description of the order that is shared in buyer communication.",
                customInformation: "Custom info for the order. This data is not shared in any buyer communication."
            }
        },
        headers: {
            'x-amz-pay-idempotency-key': SecureRandom.hex(10)
        }
    )
    if response.code.to_i == 201 || response.code.to_i == 200
        response.body
    else
        "{\"status\": \"#{response.code.to_i}\", \"body\": \"#{response.body}\"}"
    end
end

# /authのresponseが受け取れないため、globalに定義しておく
charge_id = ''

get '/thanks' do
    # Complete Checkout Session
    response = client.api_call("checkoutSessions/#{params['amazonCheckoutSessionId']}/complete", 'POST',
        payload: {
            chargeAmount: {
                amount: '29980',
                currencyCode: "JPY"
            }
        }
    )
    if response.code.to_i == 201 || response.code.to_i == 200
        body = JSON.parse(response.body)
        erb :thanks, locals: {
            response: body,
            # response: JSON.parse(charge_id)
            # charge_id: charge_id
        }
    else
        erb :error, locals: {status: response.code.to_i, body: response.body}
    end
end

post '/refunds' do
    response = client.api_call("refunds", 'POST',
        payload: {
            chargeId: params[:charge_id],
            # chargeId: params,
            refundAmount: {
                amount: "29980",
                currencyCode: "JPY"
            }
        },
        headers: {
            'x-amz-pay-idempotency-key': SecureRandom.hex(10)
        }
    )
    if response.code.to_i == 201 || response.code.to_i == 200
        erb :thanks, locals: {
            response: JSON.parse(response.body)
        }
    else
        erb :error, locals: {status: response.code.to_i, body: response.body}
    end
end


get '/verify' do
    # response = client.api_call("refunds/S03-1110432-8546949-R087555", 'GET')
    response = client.api_call("refunds/#{params['refund_id']}", 'GET')
    if response.code.to_i == 201 || response.code.to_i == 200
        erb :thanks, locals: {
            response: JSON.parse(response.body)
        }
    else
        erb :error, locals: {status: response.code.to_i, body: response.body}
    end
end
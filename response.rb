# 購入者を知れる情報
# http://amazonpay-integration.amazon.co.jp/amazonpay-faq-v2/detail.html?id=QA-8

# shippingAddress
# city, county, districtは日本で使わない
{
  "name"=>"テスト姓名二",
  "addressLine1"=>"住所1(横浜市港北区日吉本町)",
  "addressLine2"=>"住所2(3-21-5-210)",
  "addressLine3"=>"住所3（会社名）",
  "city"=>nil,
  "county"=>nil,
  "district"=>nil,
  "stateOrRegion"=>"Tokyo",
  "postalCode"=>"1530064",
  "countryCode"=>"JP",
  "phoneNumber"=>"‪0312345678"
}

# buyer
{
  "name"=>"大石海渡",
  "email"=>"kaito990626@yahoo.co.jp",
  "buyerId"=>"amzn1.account.AG6FQW5XI6K4MPV63WVBZGKT6X2A",
  "primeMembershipTypes"=>nil,
  "phoneNumber"=>nil
}

  "deliverySpecifications": {
    "addressRestrictions": {
      "type": "Allowed",
      "restrictions": {
        "JP": {
          "statesOrRegions": [
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
}

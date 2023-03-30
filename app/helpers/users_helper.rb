module UsersHelper
  def process_cart(cart)
    # Parse GraphQL results

    cart = cart["data"]["cart"]
    lines = cart["lines"]["edges"].map { |line| line["node"] }
    lines.map { |line| 
      line["merchandise"]["image"] = line["merchandise"]["image"]["url"]
      line["merchandise"]["size"] = (line["merchandise"]["selectedOptions"].find { |option| option["name"] == "Size" })["value"]
      line["merchandise"]["color"] = (line["merchandise"]["selectedOptions"].find { |option| option["name"] == "Color" })["value"]
      line["merchandise"]["productTitle"] = line["merchandise"]["product"]["title"]
      line["merchandise"].delete("product")
      line["merchandise"].delete("selectedOptions")
      line["merchandise"].delete("__typename")
      line["cost"]["totalAmount"] = number_with_precision(line["cost"]["totalAmount"]["amount"], precision: 2).to_s
      line["cost"]["amountPerQuantity"] = number_with_precision(line["cost"]["amountPerQuantity"]["amount"], precision: 2).to_s
      line
    }
    cart["lines"] = lines
    cart
  end

  def get_cart_query(cart_id)
    query = <<-QUERY
    {
      cart(id: "#{cart_id}") {
        # Cart fields
        id
        checkoutUrl
        lines(first: 10) {
          edges {
            node {
              id
              merchandise {
                __typename
                ... on ProductVariant {
                  id
                  image {
                    url
                  }
                  selectedOptions {
                    name
                    value
                  }
                  product {
                    title
                  }
                }
              }
              cost {
                totalAmount {
                  amount
                }
                amountPerQuantity {
                  amount
                }
              }
              quantity
            }
          }
        }
      }
    }
    QUERY
  end
end

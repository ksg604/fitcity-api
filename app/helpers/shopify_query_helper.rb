module ShopifyQueryHelper
  def process_product(product)
    # Parse GraphQL results
    variants = product["variants"]["edges"].map { |variant| variant["node"] }
    variants.map! { |variant| 
      variant["price"] = number_with_precision(variant["price"]["amount"], precision: 2).to_s
      variant["image"] = variant["image"]["url"]; 
      variant["size"] = (variant["selectedOptions"].find { |option| option["name"] == "Size" })["value"];
      variant["color"] = (variant["selectedOptions"].find { |option| option["name"] == "Color" })["value"];
      variant.delete("selectedOptions");
      variant }

    product["variants"] = variants
    product["sizes"] = (variants.map { |variant| variant["size"] }).uniq
    product["colors"] = (variants.map { |variant| {color: variant["color"], image: variant["image"]}}).uniq

    safe_list_sanitizer = Rails::Html::SafeListSanitizer.new
    product["descriptionHtml"] = safe_list_sanitizer.sanitize(product["descriptionHtml"])
    product
  end
end

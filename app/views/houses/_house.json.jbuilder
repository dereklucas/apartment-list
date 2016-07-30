json.extract! house, :id, :address, :sqft, :lot, :url, :description, :photo, :hidden_at, :pets, :created_at, :updated_at
json.url house_url(house, format: :json)
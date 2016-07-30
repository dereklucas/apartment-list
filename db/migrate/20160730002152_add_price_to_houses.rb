class AddPriceToHouses < ActiveRecord::Migration[5.0]
  def change
    add_column :houses, :price, :text
  end
end

class CreateHouses < ActiveRecord::Migration[5.0]
  def change
    create_table :houses do |t|
      t.text :address
      t.string :sqft
      t.string :lot
      t.string :url
      t.text :description
      t.text :photo
      t.datetime :hidden_at
      t.boolean :pets

      t.timestamps
    end
  end
end

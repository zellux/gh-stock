class CreateStockData < ActiveRecord::Migration
  def change
    create_table :stock_data do |t|

      t.timestamps
    end
  end
end

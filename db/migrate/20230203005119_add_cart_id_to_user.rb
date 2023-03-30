class AddCartIdToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :cart_id, :string
  end
end

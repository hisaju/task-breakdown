class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false, limit: 50
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.datetime :terms_accepted_at, null: false

      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end

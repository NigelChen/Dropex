class CreateDefiles < ActiveRecord::Migration
  def change
    create_table :defiles do |t|
      t.string :name
      t.string :maskedName
      t.datetime :toDestroy

      t.timestamps null: false
    end
  end
end

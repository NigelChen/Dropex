class AddFileCodeToDefile < ActiveRecord::Migration
  def change
    add_column :defiles, :filecode, :string
  end
end

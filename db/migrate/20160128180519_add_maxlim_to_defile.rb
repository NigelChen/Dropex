class AddMaxlimToDefile < ActiveRecord::Migration
  def change
    add_column :defiles, :maxlim, :integer
  end
end

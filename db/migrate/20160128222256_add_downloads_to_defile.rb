class AddDownloadsToDefile < ActiveRecord::Migration
  def change
    add_column :defiles, :downloads, :integer
  end
end

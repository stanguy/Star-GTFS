class AddFeedinfoToAgencies < ActiveRecord::Migration
  def change
    add_column :agencies, :publisher, :string
    add_column :agencies, :feed_url, :string
    add_column :agencies, :feed_ref, :string

  end
end

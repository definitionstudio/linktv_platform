class Admin::PlaylistsController < Admin::AdminController

  active_scaffold :playlists do |config|
    config.list.columns =
      [:display_order, :name, :user, :playlist_items]
    config.create.columns = config.update.columns =
      [:name, :display_order, :user]
    config.show.columns =
      [:name, :display_order, :user, :playlist_items, :created_at, :updated_at]
    config.columns[:user].form_ui = :select
  end

end

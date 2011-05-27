class Admin::PlaylistItemsController < Admin::AdminController

  active_scaffold :playlist_items do |config|
    config.label = "Playlist Items"
    config.actions = [:list, :delete]
    config.list.columns = [:playlist, :playlistable_item]

    # active_scaffold_sortable config
    config.actions.add :sortable
    config.sortable.column = :display_order
  end

  before_filter :process_playlist_id
  def process_playlist_id

    return unless params[:playlist_id] || nil
    playlist = Playlist.find params[:playlist_id]
    return unless playlist.present?

    active_scaffold_config.label =
      "Items in #{playlist.user_id == nil ? "Global" : ""} Playlist \"#{playlist.name}\""
    active_scaffold_config.list.columns.exclude :playlist
  end
  
end

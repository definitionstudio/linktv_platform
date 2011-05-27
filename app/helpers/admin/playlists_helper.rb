module Admin::PlaylistsHelper

  def playlist_playlist_items_column record
    "<ul>" +
      record.playlist_items.ordered.collect{|item|
        "<li><a href=\"#{polymorphic_path([:admin, item.playlistable_item])}\">" +
        "<span title=\"Display order\">#{item.display_order}</span> - " +
        "#{item.to_label}</a></li>" }.join +
    "</ul>".html_safe!
  end
  safe_helper :playlist_playlist_items_column

  def playlist_name_column record
    link_to record.name, admin_playlist_items_path + "?playlist_id=#{record.id}"
  end

end

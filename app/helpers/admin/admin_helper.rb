module Admin::AdminHelper
  
  def show_hide_controls
    render_to_string :partial => 'admin/show_hide_controls'
  end
  safe_helper :show_hide_controls

  def in_place_edit_controls
    render_to_string :partial => 'admin/in_place_edit_controls'
  end
  safe_helper :in_place_edit_controls

end


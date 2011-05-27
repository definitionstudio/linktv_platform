class SuperAdmin::SuperAdminController < Admin::AdminController

  def authorize_admin
    authorize :super_admin
  end

  def set_title
    @template.content_for :title, "Super Admin - " + self.controller_name.titleize
  end

end

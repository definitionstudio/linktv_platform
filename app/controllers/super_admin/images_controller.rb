class SuperAdmin::ImagesController < SuperAdmin::SuperAdminController

  active_scaffold :images do |config|
    config.list.columns =
      [:filename]
    config.show.columns =
      [:filename, :created_at, :updated_at]
    config.create.columns = config.update.columns =
      [:filename]
  end

end

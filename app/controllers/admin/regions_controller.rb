class Admin::RegionsController < Admin::AdminController

  active_scaffold :regions do |config|
    config.list.columns =
      [:name, :code]
    config.show.columns =
      [:name, :code, :created_at, :updated_at]
    config.create.columns = config.update.columns =
      [:name, :code]
  end
  
end

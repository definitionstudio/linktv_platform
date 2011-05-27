class SuperAdmin::CountriesController < SuperAdmin::SuperAdminController

  active_scaffold :countries do |config|
    config.list.columns =
    config.create.columns = config.update.columns =
      [:name, :iso3166_1_alpha_2, :iso3166_1_alpha_3, :iso3166_1_numeric]
    config.show.columns =
      [:name, :iso3166_1_alpha_2, :iso3166_1_alpha_3, :iso3166_1_numeric, :created_at, :updated_at]
  end

end

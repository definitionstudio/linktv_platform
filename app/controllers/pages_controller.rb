class PagesController < FrontEndController

  def show
    path = File.join '/', params['path']
    @page = Page.live.find_by_path path
    raise Exceptions::HTTPNotFound if @page.nil?
    @page_title += " - #{@page.name}"
  end

end

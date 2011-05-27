class HomeController < FrontEndController

  helper :topics, :videos, :images
  
  def index
    @page_title += " - Home"
    @featured_videos = Video.include_thumbnail.in_playlist(nil, "featured-videos").available
    @featured_topics = Topic.live.group('topics.id').featured.videos_available.with_video_count
  end

end

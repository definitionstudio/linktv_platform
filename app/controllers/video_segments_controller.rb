class VideoSegmentsController < FrontEndController

  before_filter :find_video_segment
  def find_video_segment
    @video_segment = VideoSegment.find params[:id]
  end

  helper :images, :videos, :video_segments, :external_contents

  def show
    @video_segment.check_external_contents :block => true
    @video_segment.load_contents_data

    # get segment index
    @video_segment_index = 0
    i = 0
    @video_segment.video.video_segments.each do |vs|
      if vs.id == @video_segment.id
        @video_segment_index = i
        break
      end
      i += 1
    end

    if request.xhr?
      render :json => {
        :status => 'success',
        :html => render_to_string(:layout => false)
      }
    end
  end

  protected

  include Linktv::Platform::VideoPlayer::ControllerMixin

end

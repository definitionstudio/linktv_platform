module Linktv::Platform::VideoPlayer

  module ControllerMixin

    def init_player_config
      @player_config = {
        :embedded => @player_type == 'embedded' ? true : false,
        :startTime => @start,
        :userId => current_user.nil? ? 0 : current_user.id,
        :googleAnalyticsId => APP_CONFIG[:google_analytics][:account_id],
        :permalinkId => @video.permalink,
        :permalinkUrl => video_url(@video.permalink),
        :streamHost => APP_CONFIG[:video_host][:stream_host] || nil,
        :trackPlayUrl => register_play_video_url(@video.permalink),
        :mediaType => @video.media_type,
        :media => [],
        :duration => @video.duration,
        :title => @video.name,
        :description => @video.description,
        :additionalInfo => @more_info.nil? ? '' : @more_info.value,
        :segments => [],
        :player => @player_options[:player][:config].present? ? @player_options[:player][:config] : {}
      }
      unless @video.thumbnail.nil?
        @player_config[:posterImage] = @template.thumbnail_url @video.thumbnail,
          :width => @player_options[:player][:width],
          :height => @player_options[:player][:height],
          :crop => :center,
          :format => @player_options[:player][:format] || :jpg
        @player_config[:posterAttribution] = @video.thumbnail_attribution
      end
      @video_files.each {|vf|
        file = {
          :url => vf.identifier,
          :size => vf.file_size.present? ? vf.file_size : nil
        }
        @player_config[:media].push(file)
      }
      @video_segments.each {|vs|
        segment = {
          :id => vs.id,
          :startTime => vs.start_time,
          :title => vs.name,
          :thumbnail => vs.thumbnail.nil? ? nil : (@template.thumbnail_url vs.thumbnail, :width => 50, :height => 50, :crop => :center)
        }
        @player_config[:segments].push(segment)
      }
      if @video.unrestricted? request_country
        @player_config[:mediaStatus] = { :available => true, :message => '' }
      else
        @player_config = { :mediaStatus => { :available => false, :message => @template.restricted_video_message } }
      end

      if @player_type == 'embedded' && !@video.embeddable
        @player_config = { :mediaStatus => { :available => false, :message => @template.restricted_video_embed_message } }
      end

      customize_player_config
    end

    # override this method in your controller
    # to customize the generated @player_config
    def customize_player_config
    end

  end

end

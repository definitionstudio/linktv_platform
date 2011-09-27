var VideoEdit = {

  playerConfig: {},

  accordionParams: {
    active: false,
    autoHeight: false,
    collapsible: true,
    changestart: function(event, ui) {
      var elem = $j(this).find('.segment-header.ui-state-active');
      var target = elem.next();
      if (!target.hasClass('state-unloaded')) return;
      
      Admin.ajax({
        dataType: 'json',
        url: target.find('a').attr('href'),
        target: target,
        afterSuccess: function(data, textStatus, xhr) {
          var tabs = $j('#video-segments .segment-tabs.do-init');
          VideoEditTopics.init($j("#video-segments-accordion"));
          VideoEdit.initSegmentTabs(tabs);
          tabs.removeClass('do-init');
          target.removeClass('state-unloaded');
        }
      });
    }
  },

  init: function(config) {
    // init player config
    for(var c in config) {
      this.playerConfig[c] = config[c];
    }

    var segmentAccordion = $j("#video-segments-accordion");
    segmentAccordion.accordion(VideoEdit.accordionParams);

    $j('#video-tabs, #video-files-tabs').tabs().removeClass('ui-widget-content').show();

    $j('#video-undelete').click(function(event) {
      event.preventDefault();
      Admin.ajax({
        url: $j(this).attr('href'),
        type: 'POST'
      });
    });

    // Bind video events
    $j('#video_duration').bind('change', function(event) {
      var target = $j(this);
      setTimeout(function() {
        // Reformat into HH:MM:SS
        var time = VideoEdit.formatTime(target.val());
        if (time) {
          target.val(time);
        } else {
          target.focus().select();
        }
      });
      return false;
    });

    $j("#add-segment").bind('click', function() {
      var target = $j(this);
      setTimeout(function() {
        if (target.hasClass('state-disabled')) return;
        VideoEdit.newSegment();
      });
      return false;
    });

    // Override default click handler
    $j('form.edit_imported_video').find('input.accept, input.reject').bind('click', function(event) {
      var elem = $j(this);
      if (elem.hasClass('accept')) {
        $j('#operation').val('accept');
      } else {
        $j('#operation').val('reject');
      }
      elem.trigger('operation-trigger');
    });

    $j('form.edit_video, form.edit_imported_video').bind('operation-handle', function(event) {
      var form = $j(this);

      setTimeout(function() {
        // Ensure there are no open in-place-edit controls
        var editActiveCount = $j('.in-place-edit-active').length;
        if (editActiveCount > 0) {
          $j(event.target).trigger('operation-end');
          alert("There are currently " + editActiveCount + " in-place-edit region(s) active.\r\n" +
            "Please either accept or cancel before saving.");
          return false;
        }

        // Don't send non-static content
        VideoEdit.disableUnmodifiedContent();

        Admin.ajax({
          type: 'POST',
          url: form.attr('action'),
          dataType: 'json',
          data: form.serializeArray(),
          trigger: $j(event.target),
          success: function(data, textStatus, xhr) {
            Admin.clearContentModified();
          }
        });
      });
      return false;
    });

    Admin.initInPlaceEdit($j('form.edit_video'), {
      tinyMCESelector: '.tinymce',
      tinyMCEOptions: {
        script_url: '/assets/linktv_platform/javascripts/admin/tiny_mce/tiny_mce.js',
        forced_root_block : false,
        theme: "advanced",
        theme_advanced_toolbar_align: "left",
        theme_advanced_buttons1: "bold,italic,underline,cut,copy,paste,link,unlink",
        theme_advanced_buttons2: null,
        theme_advanced_buttons3: null,
        theme_advanced_buttons4: null,
        theme_advanced_toolbar_location: "top",
        width: "100%",
        height: "100",
        onchange_callback: Admin.setContentModified
      }
    });

    // Published date
    var publishedAt = $j('#published-at');
    $j('input.datepicker', publishedAt).datepicker();

    VideoEdit.initGeoRestrictions();

    //
    // Bind events within video "video" section
    //

    $j('#video-video').delegate('.video-player-internal, .video-player-youtube', 'update-video-player', function(event, url) {
      var elem = $j(this);

      var object = elem.parents('.object-video-player');
      object.toggleClass('state-video-present', url && url != "");

      if (elem.hasClass('video-player-internal')) {
        // Update a internal video player for a newly entered URL
        var player = $j('.flowplayer', elem);
        if (player[0]) {
          var fp = flowplayer(player[0]);
          var playerId = fp.id();

          var pConf = VideoEdit.playerConfig;
          var FPconfig = {
            clip: {
               url: url,
               autoPlay: false,
               scaling: 'orig'
            }
          }

          // FlowPlayer update() does not work!
          //fp.getClip(0).update({url: url});

          // so, unload & redraw the player
          fp.unload();
          flowplayer(playerId, {src: pConf.flowplayer_swf}, {
            clip: {
               url: url,
               autoPlay: false,
               scaling: 'orig'
            }
          });
        }

      } else if (elem.hasClass('video-player-youtube')) {
        // Update a YouTube API player for a newly entered URL
        var matches = url.match(/^http:\/\/(?:www\.)?youtube\.com\/v\/([^&\/]*)/i);           // format: http://www.youtube.com/v/:id....
        if (!matches)
          matches = url.match(/^http:\/\/(?:www\.)?youtube\.com\/watch\?(?:.+&)*v=([^&]*)/i); // format: http://www.youtube.com/watch?v=:id....
        if(!matches)
          matches = url.match(/^http:\/\/youtu\.be\/([^&\/]*)/i);                             // format: http://youtu.be/:id

        if(matches && matches[1]) {
          VideoEdit.initYoutubePlayer(elem.find('.ytapiplayer').attr('id'), matches[1]);
          // load video metadata from YouTube API
          $j.getScript('http://gdata.youtube.com/feeds/api/videos/'+matches[1]+'?alt=jsonc&v=2&callback=VideoEdit.parseYoutubeMetadata');
        } else {
          alert('Invalid YouTube URL entered. Please check and try again.');
        }
        return false;
      }
    });

    //
    // Bind events within video tabs section
    //

    $j('#video-tabs').delegate('a.download-from-source', 'click', function(event) {   // TODO: deprecated?
      var target = $j(this);
      setTimeout(function() {
        if (confirm("Confirm re-download video from source URL? Any changes on the video files tab since last save will be lost.")) {
          var context = target.parents('.busy-context:first');
          Admin.ajax({
            dataType: 'json',
            url: target.attr('href'),
            type: 'POST',
            target: target.parents('.ajax-context:first')
          });
        }
      });
      return true;
        
    }).delegate('#video_media_type', 'change', function(event) {
      // Media type select changed: show the media for the selected media type
      var elem = $j(this);
      var context = elem.parents('.media-content-context:first');
      var mediaType = elem.val();
      var panelId = "video-media-type-" + mediaType;
      $j('.video-media-type', context).hide();
      $j('#' + panelId).show();
      VideoEdit.initVideoFilesSelect(mediaType);
      
    }).delegate('.video-media-instance-type', 'changed', function(event) {
      // When a video file url is changed, trigger an update for the appropriate video player to update
      var elem = $j(this).find('input.video-file-url');
      var panelId = elem.attr('data-video-panel-id');
      $j('#' + panelId).find('.video-player-handler').trigger('update-video-player', [$j.trim(elem.val())]);
      return true;
    });

    // Show the media for the initially selected media type
    $j('#video_media_type').trigger('change');

    //
    // Bind events within video segment accordion
    //

    function updateSegmentHeader(segment) {
      // segment should be .object-video-segment
      var header = segment.prev('.segment-header');
      var title = $j.trim(segment.find('input.segment-title').val());
      if (title == '')
        title = "Untitled segment";
      header.find('.segment-header-time').text(segment.find('input.start-time').val());
      header.find('.segment-header-title').text(title);
    }

    // Video segment details
    segmentAccordion.delegate('input.start-time, input.segment-title', 'keypress', function(event) {
      // Update the accordion header
      var target = $j(this);
      setTimeout(function() {
        updateSegmentHeader(target.parents('.object-video-segment:first'));
      });
      return true;

    }).delegate('input.start-time', 'change', function(event) {
      var target = $j(this);
      setTimeout(function() {
        // Reformat into HH:MM:SS
        var time = VideoEdit.formatTime(target.val());
        if (time) {
          target.val(time);
          updateSegmentHeader(target.parents('.object-video-segment:first'));
        } else {
          target.focus().select();
        }
      });

    }).delegate('a.segment-in', 'click', function(event) {
      // Capture the start time from the video playhead position
      var target = $j(this);
      setTimeout(function() {
        if (target.hasClass('state-disabled')) return;
        target.parents('div.segment-panel-details:first').find('input.start-time').
          val(VideoEdit.formatTime(VideoEdit.getVideoPlayheadTime()));
        Admin.setContentModified();
      });
      return false;

    }).delegate('a.delete-segment', 'operation-handle', function(event) {
      var target = $j(this);
      setTimeout(function() {
        if (confirm("Are you sure you want to delete the segment?")) {
          VideoEdit.deleteSegment(target.parents('.object-video-segment:first'));
          if ($j("#video-segments-accordion .object-video-segment").not('#object-video-segment-model').
              not('.state-deleted').length == 0) {
            // Add back in the initial segment, one is always required
            VideoEdit.newSegment();
            alert("The last video segment for this video has been deleted. A new one has been automatically added.")
          }
        }
      });
      return false;

    }).delegate('textarea.transcript-text', 'change', function(event) {
      var target = $j(this);
      setTimeout(function() {
        var segment = target.parents('.object-video-segment:first');
        VideoEdit.updateSegmentState(segment);
      });

    // Topics
    }).delegate('a.delete-topic', 'click', function(event) {
      var target = $j(this);
      setTimeout(function() {
        if (target.hasClass('state-disabled')) return;
        var topic = target.parents('.object-topic-with-controls:first').hide();
        topic.addClass('state-deleted static-static').find('input.destroy').val(1);
        var segment = topic.parents('.object-video-segment:first');
        VideoEdit.updateSegmentState(segment);
        Admin.setContentModified();
      });
      return false;

    }).delegate('a.query-topics', 'operation-handle', function(event) {
      var target = $j(this);
      setTimeout(function() {
        VideoEditTopics.query(target, {
          complete: function() {
            $j(target).trigger('operation-end', event);
          }
        });
      });
      return false;

    }).delegate('button.add-topic', 'operation-handle', function(event) {
      var target = $j(this);
      setTimeout(function() {
        VideoEditTopics.newTopic(target.parents('.object-video-segment:first'), {
          event: event
        });
      }, 1);
      return false;

    // Suggested keywords (not yet mapped to a topic)
    }).delegate('a.inline-suggested-keyword', 'click', function(event) {
      var target = $j(this);
      setTimeout(function() {
        VideoEditTopics.newTopic(target.parents('.object-video-segment:first'), {
          name: target.parents('.object-suggested-keyword:first').attr('data-name'),
          afterCreate: function() {
            target.parents('li:first').remove();
          }
        });
      });
      return false;

    // Suggested topics
    }).delegate('a.inline-suggested-topic', 'click', function(event) {
      var target = $j(this);
      setTimeout(function() {
        // Make sure topic isn't already present
        var topic_id = target.find('.object-topic:first').attr('data-id');
        var segment = target.parents('.object-video-segment:first');
        var topicsData = VideoEditTopics.getTopicsData(segment);
        var idx, topicData;
        for (idx in topicsData) {
          topicData = topicsData[idx];
          if (topicData.id == topic_id) {
            alert("The topic is already associated with the video segment.");
            return;
          }
        }
        VideoEditTopics.appendTopic(target.parents('.object-suggested-topic:first').
          find('.segment-topic-template:first'), target.parents('.object-video-segment:first'));
      });
      return false;

    }).delegate('a.link-suggested-topic', 'click', function(event) {
      // Link to an existing topic
      // Move the suggested topic contained in the current element into the topics table.
      var target = $j(this);
      setTimeout(function() {
        VideoEditTopics.moveToTopics(target.parents('.object-suggested-topic:first'),
          target.parents('.object-video-segment:first'));
      });
      return false;

    }).delegate('a.create-disambiguated-suggested-topic', 'click', function(event) {
      // Create topic that does not yet exist, but has disambiguity information
      // Then move the suggested topic contained in the current element into the topics table.
      var target = $j(this);
      setTimeout(function() {
        var topic = target.parents('.object-suggested-topic:first');
        var segment = topic.parents('.object-video-segment:first');
        var dummyForm = $j("<form>" +
          $j('.segment-topic-template', topic).html() +
          // Manaully add other fields since we are serializing params to a query string
          "<input name='score' value='" + topic.attr('data-score') + "'/>" +
          "</form>");
        $j('input', dummyForm).attr('disabled', false);
        target.parents('.object-suggested-topic:first').remove();
        VideoEditTopics.createTopic(segment, dummyForm.serialize());
      });
      return false;

    }).delegate('a.create-suggested-topic', 'click', function(event) {
      var target = $j(this);
      setTimeout(function() {
        VideoEditTopics.newTopic(target.parents('.object-video-segment:first'), {
          name: target.parents('.object-suggested-topic:first').attr('data-name'),
          afterCreate: function() {
            target.parents('.object-suggested-topic:first').remove();
          }
        });
      });
      return false;

    // External content
    }).delegate('a.refresh-external-contents', 'operation-handle', function(event) {
      var target = $j(this);
      setTimeout(function() {
        VideoEditExternalContent.refresh(target.parents('.object-content-type:first'), {
          event: event
        });
      });
      return false;

    }).delegate('a.query-external-contents', 'operation-handle', function(event) {
      var target = $j(this);
      setTimeout(function() {
        VideoEditExternalContent.query(target.parents('.object-content-type:first'), {
          event: event
        });
      });
      return false;

    }).delegate('a.add-external-content', 'operation-handle', function(event) {
      var target = $j(this);
      setTimeout(function() {
        VideoEditExternalContent.newContent(target, {
          event: event
        });
      });
      return false;

    }).delegate('a.stick-external-content', 'click', function(event) {
      var target = $j(this);
      setTimeout(function() {
        if (target.hasClass('state-disabled')) return;
        var object = target.parents('.object-external-content:first');
        if (object.hasClass('state-deleted')) return;
        VideoEditExternalContent.setSticky(object, !parseInt(object.attr('data-sticky')));
      });
      return false;

    }).delegate('a.delete-external-content', 'click', function(event) {
      var target = $j(this);
      setTimeout(function() {
        if (target.hasClass('state-disabled')) return;
        var object = target.parents('.object-external-content:first');
        VideoEditExternalContent.setDeleted(object, !object.is('.state-deleted'));
      });
      return false;
    });

    $j('#video-segments').show();

    // Video file selector (media player)
    $j('#video-files-select').bind('change', function() {
      var elem = $j(this);
      var context = $j('#video-files-panels');
      context.find('.video-file-panel').hide();
      $j('#' + elem.val()).show();
    }).trigger('change');

    // Bind input changes for "modified" detection
    $j('#video').delegate('input,textarea,select', 'change', Admin.setContentModified);

    // Currenty unused, but keep around
    //$j(document).trigger('video-edit-after-init');
  },

  initVideoFilesSelect: function(mediaType) {
    var videoFilesSelect = $j('#video-files-select');
    videoFilesSelect.find('option').attr('disabled', true);
    videoFilesSelect.find('option[data-media-type="' + mediaType + '"]').attr('disabled', false);

    var id = null;
    var present = false;
    $j('#video-files-panels .video-file-panel[data-media-type="' + mediaType + '"]').each(function() {
      if (present) return;
      var elem = $j(this);
      id = elem.attr('id');
      if (elem.find('.object-video-player.state-video-present:first').length > 0) {
        present = true;
      }
    });
    if (id) {
      videoFilesSelect.val(id).trigger('change');
    }
  },

  initYoutubePlayer: function(ytapiplayerId, youtubeVideoId, args) {
    console.log('initYoutubePlayer', ytapiplayerId, youtubeVideoId);
    var pConf = VideoEdit.playerConfig;
    try {
      var width = args.width;
      var height = args.height;
    } catch (err) {
      width = pConf.player_width;
      height = pConf.player_height;
    }
    var params = { allowScriptAccess: "always" };
    var atts = { id: 'youtube-player', styleclass: 'ytapiplayer' };
    swfobject.embedSWF("http://www.youtube.com/v/" + youtubeVideoId + "?enablejsapi=1",
      ytapiplayerId, width, height, "9.0.115", null, null, params, atts);
  },

  parseYoutubeMetadata: function(apidata) {
    try {
      if(!apidata.data) {
          alert('[YouTube] Video not found. Check the URL and try again.');
          return;
      }
      if(apidata.data.accessControl.embed != "allowed") alert('[YouTube] Embedding not enabled by the video owner.');

      if(!$j('#update-youtube-metadata:checked').length) return;

      var titleField = $j('#video_name');
      $j(titleField).val(apidata.data.title);
      $j(titleField).siblings('.in-place-edit-value').text(apidata.data.title);

      var duration = VideoEdit.formatTime(apidata.data.duration);
      var durationField = $j('#video_duration');
      $j(durationField).val(duration);
      $j(durationField).siblings('.in-place-edit-value').text(duration);

      var descriptionField = $j('#video_description');
      $j(descriptionField).val(apidata.data.description);
      $j(descriptionField).siblings('.in-place-edit-value').text(apidata.data.description);

      var sourceNameField = $j('#video_source_name');
      $j(sourceNameField).val(apidata.data.uploader);
      $j(sourceNameField).siblings('.in-place-edit-value').text(apidata.data.uploader);

      var sourceLinkField = $j('#video_source_link');
      var sourceLinkURI = 'http://www.youtube.com/'+apidata.data.uploader;
      $j(sourceLinkField).val(sourceLinkURI);
      $j(sourceLinkField).siblings('.in-place-edit-value').text(sourceLinkURI);

    } catch(err) {}
  },

  initGeoRestrictions: function() {
    // Geo-restrictions autocomplete
    var geo = $j('#restricted_countries_autocomplete');
    var geoContext = geo.parents('.in-place-edit-context:first');

    // TODO why not using Admin.ajax here?
    geo.autocomplete({
      minLength: 2,
      delay: 800,
      source: function(request, response) {
        $j.ajax({
          url: geo.attr('data-url'),
          dataType: "json",
          data: {
            q: request.term
          },
          success: function(data) {
            response(data.data.map(function(item) {
              return {
                label: item.label,
                value: item.label,
                id: item.id
              }
            }));
          }
        });
      },
      select: function(event, ui) {
        var item = $j(ui.item)[0];

        // Add new country to the hidden select
        var select = geoContext.find('select.hidden-select');
        var selected = select.find('option[value="' + item.id + '"]');
        if (selected.length == 0) {
          // Add item to the select
          select.trigger('addItem', {id: item.id, value: item.label});
        }
      },
      close: function(event, ui) {
        geo.val('');
      }
    });
  },

  initSegmentTabs: function(segmentTabs) {
    segmentTabs.tabs({
      show: function(event, ui) {
        var panel = $j(ui.panel);
        var segment = panel.parents('.object-video-segment:first');
        VideoEdit.updateSegmentState(segment);
        if (panel.hasClass('segment-panel-topics')) {
          // Query suggested topics if none exist but transcript is present
          if (!segment.hasClass('state-has-topics') && segment.hasClass('state-has-transcript')) {
            // Delegate via the link, whose href is required to handle the operation
            $j('a.query-topics', panel).trigger('operation-trigger');
          }
        } else if (panel.hasClass('segment-panel-external-contents')) {
          // Reload external content if none are present and if topics exist
          if (!segment.hasClass('state-has-topics')) return;
          if (panel.find('.object-external-content:first').length > 0) return;
          panel.find('a.query-external-contents').trigger('operation-trigger');
        }
      }
    });
  },

  updateSegmentState: function(segment) {
    var transcript = VideoEdit.getSegmentTranscript(segment);
    if (transcript.length) {
      segment.addClass('state-has-transcript');
    } else {
      segment.removeClass('state-has-transcript');
    }

    var topics = VideoEdit.getSegmentTopics(segment);
    if (topics.length) {
      segment.addClass('state-has-topics');
    } else {
      segment.removeClass('state-has-topics');
    }
  },

  getSegmentTranscript: function(segment) {
    return $j.trim(segment.find('div.segment-tabs-details div.segment-panel-details textarea.transcript-text').val());
  },

  // TODO: this is not DRY against getTopicsData -- combine the functions
  getSegmentTopics: function(segment) {
    return segment.find('div.segment-tabs-details div.segment-panel-topics .segment-topics tr.object-topic-with-controls').not('.state-deleted');
  },

  getVideoPlayheadTime: function() {
    // Note: if flashblock is installed, the getTime() call fails.
    try {
      var flowPlayer = $j('.flowplayer:visible');
      if (flowPlayer[0])
        return parseInt(flowplayer(flowPlayer[0]).getTime());

      var youTubePlayer = $j('#youtube-player:visible');
      if (youTubePlayer[0])
          return parseInt(youTubePlayer[0].getCurrentTime());

    } catch(err) {
      alert('Unable to get playhead time. Adding new segment at 00:00. Please adjust segment time manually. ' + err);
      return 0;
    }
    return 0;
  },

  formatTime: function(timeValue) {
    timeValue = $j.trim('' + timeValue);
    var hours, minutes, seconds;
    var matches = timeValue.match(/^((\d+):)??((\d{1,2}):)?(\d+)$/);
    if (timeValue.match(/^\d*$/)) {
      // Looks like an integer, treat as number of seconds
      var totalSeconds = parseInt(timeValue);
      hours = parseInt(totalSeconds / 3600)
      minutes = parseInt(totalSeconds % 3600 / 60);
      seconds = totalSeconds % 60;
    } else if (matches && parseInt(matches[4]) < 60 && parseInt(matches[5]) < 60) {
      // Check for HH:MM:SS or some subset
      hours = matches[2] || 0;
      minutes = matches[4] || 0;
      seconds = matches[5];
    } else {
      alert("Please check the time format and try again.\r\nTime may be entered in seconds, or in HH:MM:SS format.");
      return null;
    }
    hours = parseInt(hours);
    minutes = parseInt(minutes);
    seconds = parseInt(seconds);
    return (hours < 10 ? '0' : '') + hours + ':' + (minutes < 10 ? '0' : '') + minutes + ':' + (seconds < 10 ? '0' : '') + seconds;
  },

  newSegment: function() {
    var segmentAccordion = $j("#video-segments-accordion");
    segmentAccordion.accordion('activate', -1);

    var newIndex = new Date().getTime();
    var newSegment = $j('#segment-model-header').clone().attr('id', null).removeClass('model-object').
      after($j('#object-video-segment-model').clone().attr('id', null).removeClass('model-object').
      attr('data-index', newIndex));
    newSegment.find('.segment-index').text(newIndex);
    var time = VideoEdit.formatTime(VideoEdit.getVideoPlayheadTime());
    newSegment.find('.segment-header-time').text(time);
    // Fix inputs
    newSegment.find('.segment-panel-details :input').each(function() {
      var elem = $j(this);
      elem.attr('disabled', false);
      if (elem.is('.start-time'))
        elem.val(time);
    });
    newSegment.find(':input').each(function() {
      var elem = $j(this);
      elem.attr('name', elem.attr('name').replace(/:model/, newIndex));
      elem.attr('id', elem.attr('id').replace(/:model/, newIndex));
    });
    // Update attributes where :model is used to take the place of the index
    newSegment.find('.indexed').each(function() {
      var elem = $j(this);
      if (elem.is('a')) {
        elem.attr('href', elem.attr('href').replace(/:model/, newIndex));
      }
      elem.attr('id', elem.attr('id').replace(/:model/, newIndex));
    });
    newSegment.show();
    // Destroy and re-create to enable the new section
    segmentAccordion.append(newSegment).accordion('destroy').
      accordion(VideoEdit.accordionParams).accordion('activate', $j('.segment-header', segmentAccordion).length - 1);
    VideoEdit.initSegmentTabs(newSegment.find('.segment-tabs'));
    Admin.setContentModified();
  },

  deleteSegment: function(segment) {
    var segmentAccordion = $j("#video-segments-accordion");
    segment.addClass('state-deleted').find('input.delete-segment').val(1);
    // Hide the segment and its header, which will be the previous DOM element
    segment.prev().andSelf().hide();
    segmentAccordion.accordion('destroy').accordion(VideoEdit.accordionParams);
    Admin.setContentModified();
    return false;
  },

  disableUnmodifiedContent: function() {
    var contents = $j('#video-segments-accordion .segment-panel-external-contents .external-content-table .object-external-content');
    contents.each(function() {
      var content = $j(this);
      if (content.hasClass('original-state-static')) {
        // Save all originally static content
        // Stick and/or delete may have changed so always save them
        content.find(':input').attr('disabled', false);
        if (!content.hasClass('state-static')) {
          // Destroy if no longer static
          content.find('input.destroy').val(1);
        }
      } else {
        // Content was dynamic and/or new. Only save it if it has become static
        if (content.hasClass('state-static')) {
          // Content is newly static, it should be saved
          content.find(':input').attr('disabled', false);
        } else {
          content.find(':input').attr('disabled', true);
        }
      }
    });
  },

  dummy: 0
};

var VideoEditTopics = {

  init: function(context) {

    Entities.initEntityLinks(context);
    VideoEditTopics.initDynamicContent(context);
  },

  /**
   * Initialize any dynamically created content.
   * This contains any initialization that may have to be done more than once
   * on the page, i.e. ajax or javascript DOM manipulation, that cannot be
   * done using a jQuery live call.
   * Caller must ensure that .do-init tags are set on any element in the context
   * that requires processing. This should be done, for example, after the elements
   * are created or cloned.
   */
  initDynamicContent: function(context) {
    if (!context) context = $j(document);

    // Topic weight sliders
    $j('.score-slider.do-init', context).each(function() {
      $j(this).removeClass('do-init').addClass('init-done');
      VideoEditTopics.initTopicSlider.call(this);
    });

  },

  setState: function(rowElem) {
    rowElem.removeClass('state-topic-filtered state-topic-excluded state-topic-emphasized');
    var score = parseInt(rowElem.find('input.topic-score').val());
    if (score == -1) {
      rowElem.addClass('state-topic-filtered');
    } else if (score == 0) {
      rowElem.addClass('state-topic-excluded');
    } else if (score >= $j(document).data('apis_config').emphasis_threshold) {
      rowElem.addClass('state-topic-emphasized');
    }
  },

  initTopicSlider: function() {
    var elem = $j(this);
    var context = elem.parents('td:first');
    var input = $j('input', context);
    var indicator = $j('.indicator', context);
    VideoEditTopics.setState(context.parents('tr:first'));
    elem.slider({
      min: -1,
      max: 100,
      value: input.val(),
      slide: function(event, ui) {
        input.val(ui.value);
        indicator.text(ui.value);
        VideoEditTopics.setState(context.parents('tr:first'));
      },
      change: function(event, ui) {
        Admin.setContentModified();
      }
    });
  },

  moveToTopics: function(suggestedTopic, destContext) {
    var template = suggestedTopic.find('.segment-topic-template:first');
    VideoEditTopics.appendTopic(template, destContext);
    suggestedTopic.remove();
  },

  /**
   * Append a topic contained in the element to the topics table.
   *
   * elem: jQuery element containing table.segment-topic, which in turn contains only one row,
   *   the row to be appended to the topic table, complete with all the necessary form elements.
   *   Form elements will be enabled if they are disabled.
   * segment: jQuery element of the containing element (.object-video-segment) within which the target topic
   *   table will be found.
   */
  appendTopic: function(template, segment) {
    var tvs = $j('tr', template).clone();
    tvs.find('.score-slider').removeClass('init-done').addClass('do-init');
    var segmentIndex = parseInt(segment.attr('data-index'));
    var newIndex = new Date().getTime();

     // Enable each form element, and add the appropriate prefix to fit in the segment form.
    tvs.find('input').each(function() {
      var elem = $j(this);
      elem.attr('disabled', false)
        .attr('id', elem.attr('id').replace(/^topic_video_segment_(.*)$/,
          'video_video_segments_attributes_' + segmentIndex + '_topic_video_segments_attributes_' +
          newIndex + "_$1"))
        .attr('name', elem.attr('name').replace(/^topic_video_segment(.*)$/,
          'video[video_segments_attributes][' + segmentIndex + '][topic_video_segments_attributes][' +
          newIndex + ']$1'))
    });

    segment.find('table.segment-topics-table .segment-topics-body').append(tvs);
    VideoEditTopics.initDynamicContent(tvs);
    Admin.setContentModified();
  },

  /**
   * Get the existing topics for the segment (context), either for a query or
   * so they can be exluded from abother topic lookup's results.
   * These may not all be saved on the server side yet.
   */
  getTopicsData: function(context) {
    var topicsData = [];

    $j('.current-segment-topics .object-topic-with-controls', context).each(function() {
      var topic = $j(this);
      if (topic.hasClass('state-deleted')) return;
      var entityIdentifiers = {};
      $j('.object-entity-identifiers .object-entity-identifier', topic).each(function() {
        var ident = $j(this);
        entityIdentifiers[ident.attr('data-entity-db-id')] = ident.attr('data-identifier');
      });
      var topicData = {
        id: topic.attr('data-id'),
        name: topic.attr('data-name'),
        entity_identifiers: entityIdentifiers,
        score: $j('input.topic-score', topic).val()
      };
      topicsData.push(topicData);
    });

    return topicsData;
  },

  /**
   * Query for topics.
   */
  query: function(elem, options) {
    options = $j.extend({}, options);
    var context = elem.parents('.segment-suggested-topics:first').find('.ajax-context:first');
    var segment = context.parents('.object-video-segment:first');
    var segmentIndex = parseInt(segment.attr('data-index'));
    var transcript = segment.find('.transcript-text').val();
    context.addClass('state-ajax-loading');

    var data = {
      omit_topics: VideoEditTopics.getTopicsData(segment),
      segment_index: segmentIndex,
      transcript: transcript
    };

    Admin.ajax({
      type: 'post',
      url: elem.attr('href'),
      data: data,
      complete: options.complete,
      target: context,
      afterError: function(xhr, textStatus, errorThrown) {
        context.html('Error').removeClass('state-ajax-loading');
      }
    });
  },

  /**
   * Add a new topic to the segment.
   */
  newTopic: function(segment, options) {
    options = $j.extend({}, options);
    var dialogOptions = {
      event: options.event,
      url: '/admin/topic_video_segments/new',
      attachAjaxFormHandler: true,
      afterCreate: function(template) {
        VideoEditTopics.appendTopic(template, segment);
        if ($j.isFunction(options.afterCreate))
          options.afterCreate();
      },
      selectExistingTopic: function(template) {
        // Make sure topic doesn't already exist
        var topicId = $j(template).find('.object-topic').attr('data-id');
        var existing_topics = VideoEditTopics.getTopicsData(segment);
        var found = false;
        $j.each(existing_topics, function() {
          if (found) return;
          if (this.id == topicId) {
            alert('The selected topic is already linked to the video segment.');
            found = true;
          }
        });
        if (!found) {
          VideoEditTopics.appendTopic(template, segment);
          if ($j.isFunction(options.afterCreate))
            options.afterCreate();
        }
      }
    };

    Topics.newTopicDialog({
    'topic[name]': options.name
    }, dialogOptions);
  },

  createTopic: function(segment, data, options) {
    var loader = segment.find('table.segment-topics-table tbody.loader').show();
    Topics.createTopic(data, {
      url: '/admin/topic_video_segments',
      segment_index: segment.attr('data-index'),
      afterCreate: function(template) {
        VideoEditTopics.appendTopic(template, segment);
        if (options && $j.isFunction(options.afterCreate))
          options.afterCreate();
        loader.hide();
      }
    });
  }

};

var VideoEditExternalContent = {

  setManual: function(object, value) {
    if (value) {
      object.attr('data-manual', 1).attr('data-static', 1).
        addClass('state-manual state-static');
    } else {
      object.attr('data-manual', 0).attr('data-static', 0).
        removeClass('state-manual static-static');
    }
    Admin.setContentModified();
  },

  setSticky: function(object, value) {
    if (value) {
      object.attr('data-sticky', 1).attr('data-static', 1).
        addClass('state-sticky state-static').
        find('input.input-sticky').val(1);
    } else {
      object.attr('data-sticky', 0).attr('data-static', 0).
        removeClass('state-sticky static-static').
        find('input.input-sticky').val(0);
    }
    Admin.setContentModified();
  },

  setDeleted: function(object, value) {
    if (value) {
      object.attr('data-deleted', 1).attr('data-static', 1).
        addClass('state-deleted state-static').
        find('input.input-deleted').val(1);
      VideoEditExternalContent.setSticky(object, false);
    } else {
      object.attr('data-deleted', 0).attr('data-static', 0).
        removeClass('state-deleted state-static').
        find('input.input-deleted').val(0);
    }
    Admin.setContentModified();
  },

  newContent: function(elem, options) {
    options = $j.extend({}, options);
    var segment = elem.parents('.object-video-segment:first');
    var contentType = elem.parents('.object-content-type:first')
    var data = {
      external_content: {
        content_type_id: contentType.attr('data-id')
      }
    };

    var dialog;

    Admin.dialog({
      event: options.event,
      title: 'Add New ' + contentType.attr('data-name'),
      url: '/admin/external_contents/new',
      data: data,
      modal: true,
      width: 650,
      afterOpen: function(event) {
        dialog = $j(event.target);
        var uiDialog = dialog.parents('.ui-dialog:first');
        $j('input.datepicker', dialog).datepicker();
        // Ensure datepicker is on top of dialog
        $j("#ui-datepicker-div").css("z-index", uiDialog.css("z-index") + 1);
        Admin.initInPlaceEdit(dialog);
        if (options.event)
          $j(options.event.target).trigger('operation-loaded');
      },
      ajaxFormHandler: {
        formSelector: 'form',
        data: {
          provisional: true, // Don't create the record, just the form fields to do so when the video is updated
          render_for: 'external-content-table',
          segment_index: segment.attr('data-index')
        },
        ajaxOptions: {
          successJson: function(data, textStatus, xhr) {
            dialog.dialog('close');
            var table = $j('table.external-content-table', contentType);
            var object = $j(data.html).find('tbody').children();
            VideoEditExternalContent.setManual(object, 1);
            $j('tbody.content-list', table).prepend(object);
            $j('tbody.empty-indicator', table).addClass('display-none');
          }
        }
      }
    });
  },

  // Find current static external data, which should not be included in new queries
  getStaticExternalContentsData: function(context) {
    var contents = [];

    $j('.object-external-content', context).each(function() {
      var content = $j(this);
      if (parseInt(content.attr('data-static')))
        contents.push(content.attr('data-identifier'));
    });

    return contents;
  },

  /**
   * Reload external content from server.
   *
   */
  refresh: function(contentType, options) {
    options = $j.extend({}, options);
    var context = contentType.parents('.segment-panel-external-contents:first').find('.ajax-context:first');
    var segment = context.parents('.object-video-segment:first');
    var segmentIndex = parseInt(segment.attr('data-index'));
    // Zero for provisional segment id
    var segmentId = $j('input.video-segment-id', segment).val() || 0;
    var contentTypeId = contentType.attr('data-id');

    context.addClass('state-ajax-loading');

    var data = {
      content_type_id: contentTypeId,
      segment_index: segmentIndex
    };

    Admin.ajax({
      type: 'POST',
      url: '/admin/video_segments/' + segmentId + '/external_contents',
      data: data,
      target: context,
      complete: function() {
        if (options.event)
          $j(options.event.target).trigger('operation-end');
      }
    });
  },

  /**
   * Query for external content.
   */
  query: function(contentType, options) {
    options = $j.extend({}, options);
    var context = contentType.parents('.segment-panel-external-contents:first').find('.ajax-context:first');
    var segment = context.parents('.object-video-segment:first');
    var segmentIndex = parseInt(segment.attr('data-index'));
    // Zero for provisional segment id
    var segmentId = $j('input.video-segment-id', segment).val() || 0;
    var title = segment.find('.segment-title').val();
    var transcript = segment.find('.transcript-text').val();
    var contentTypeId = contentType.attr('data-id');
    var omitIdentifiers = VideoEditExternalContent.getStaticExternalContentsData(contentType);

    var data = {
      content_type_id: contentTypeId,
      omit_identifiers: omitIdentifiers,
      segment_index: segmentIndex,
      title: title,
      transcript: transcript,
      topics: VideoEditTopics.getTopicsData(segment)
    };

    Admin.ajax({
      type: 'POST',
      url: '/admin/video_segments/' + segmentId + '/query_external_contents',
      data: data,
      target: context,
      preprocessHtml: function(html) {
        // Extract the contents of the form wrapper element
        return $j(html).html();
      },
      complete: function() {
        if (options.event)
          $j(options.event.target).trigger('operation-end');
      }
    });
  },

  dummy: 0

};

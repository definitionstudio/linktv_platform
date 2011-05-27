var EmbeddedVideo = {

  videoSegmentId: null,
  
  loadSegmentContent: function(segmentId, options) {

    options = $.extend({}, options);

    if(segmentId == this.videoSegmentId) return; // prevent duplicate requests

    var target = $('#video-segment-' + segmentId);
    var url = target.data('url');

    if (!url) return;
    this.videoSegmentId = segmentId;

    var container = $('#embedded-player-related-content');
    $('#video-segments .video-segment').hide();

    $.ajax({
      url: url,
      beforeSend: function(xhr) {
        container.addClass('loading');
      },
      complete: function() {
        container.removeClass('loading');
      },
      success: function(data){
        try {
          target.html(data.html);
          target.show();
        } catch(err) {}
        // Enable the tab
        target.find('ul.tab-nav li:first').click();
      }
    });

  },

  // Flash player event handler
  videoPlayerEventHandler: function(eventObj) {
    console.log('videoPlayerEventHandler', eventObj);
    switch(eventObj.type) {
      case "segmentChange":
        var segmentId = eventObj.segment;
        this.loadSegmentContent(segmentId);
        break;
    }
  }

}
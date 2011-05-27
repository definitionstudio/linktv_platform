$(function() {
  var doc = $(document);

  /////////////////////////////////////////////////////////////////////////////
  // Index sorting
  doc.delegate('#video_order_by, #video_region, #topic_order_by', 'change', function(event) {
    window.location = $(this).val();
  });

  /////////////////////////////////////////////////////////////////////////////
  // Tabs
  doc.delegate('.tab-nav li', 'click', function(event) {
    event.preventDefault();
    var target = $(this);
    if (target.hasClass('active')) return false;

    var tabNav = target.parents('ul.tab-nav:first');
    tabNav.find('li.active').removeClass('active');
    target.addClass('active');
    var targetPanel = $(target.find('a').attr('href'));

    var activePanel = targetPanel.siblings('.tab-panel.active');
    activePanel.removeClass('active');

    targetPanel.addClass('active');
    return false;
  });


  /////////////////////////////////////////////////////////////////////////////
  // Prompted input fields

  doc.delegate('input.prompted', 'focusin focusout keyup', function(event) {

    var elem = $(this);
    var val = elem.val();
    var title = elem.attr('title');

    if (event.type == 'focusin') {
      if (val == title) elem.val('');
    } else if (event.type == 'focusout') {
      if (val == '') elem.val(title);
    }
    
    return true;
  });

  /////////////////////////////////////////////////////////////////////////////
  // Limited lists
  //

  doc.find('.limited-list').each(function() {
    var list = $(this);
    var lines = list.find('li.limited-list-item');
    var totalCount = lines.length;
    var groupSize = list.data('size') ? parseInt(list.data('size')) : 10;
    var idx = 0;
    var showingCount = 0;
    for (idx = 0; idx < totalCount && idx < groupSize; idx++) {
      $(lines[idx]).show();
      showingCount++;
    }

    function updateShowMore() {
      var showMore = list.find('.limited-list-show-more');
      if (showingCount < totalCount) {
        showMore.show();
        showMore.find('.limited-list-showing-count').text(showingCount);
        showMore.find('.limited-list-total-count').text(totalCount);
      } else {
        showMore.hide();
      }
    }

    updateShowMore();

    list.find('a.limited-list-show-more').bind('click', function() {
      var maxGroupSize = showingCount + groupSize;
      for (idx = showingCount; idx < totalCount && idx < maxGroupSize; idx++) {
        $(lines[idx]).show();
        showingCount++;
      }
      updateShowMore();

      return false;
    });

  });

});
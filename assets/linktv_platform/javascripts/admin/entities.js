Entities = {
  
  initEntityLinks: function(context) {

    $j('a.entity-identifier', context).hoverInitLive(function(event) {
      var target = $j(this);

      var title = target.find('.name').text();
      var id = target.attr('data-id'); // Will not be present for topics not yet in DB

      var content = {
        text: Admin.loadingIndicatorHtml(),
        title: title
      };

      if (id) {
        content.url = '/admin/entity_identifiers/' + id + '/lookup';
      } else {
        content.url = '/admin/entity_identifiers/lookup_by_uri';
        content.data = {
          uri: target.attr('href')
        }
      }

      target.qtip($j.extend(Admin.qtipDefaults, {
        hide: {},
        content: content
      }));
      // Fire the event again so that it will be handled by qtip
      target.mouseover();
    });

    // TODO this really should be in topics.js, but the init needs to happen at the same time
    // as the similar entity binding above.
    // Ideally we need a delegate on-create event or something to initialize the popups.
    $j('.existing-topic', context).hoverInitLive(function(event) {
      var target = $j(this);

      // Perform the init on the first mouseoever, then re-fire the event so qtip handles it
      if (target.data('qtip-init-done')) return;
      target.data('qtip-init-done', true);

      target.qtip($j.extend(Admin.qtipDefaults, {
        content: {
          text: Admin.loadingIndicatorHtml(),
          title: target.attr('data-name'),
          url: '/admin/topics/' + target.attr('data-id'),
          ifModified: true,
          data: {
            tooltip: 1
          }
        }
      }));
      target.mouseover();
    });
  }

}

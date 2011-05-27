/**
* jquery-hover-init allows a handler to be found to an element which is fired
* only the first time the mouse enters the element.
* Useful for things like setting up other plugins which a called with the
* element, and using a jQuery live handler to initialize all matching elements
* as needed.
*
* jquery-hover-init 1.0 jQuery 1.4.1+
* <http://www.fullware.net/jquery-hover-init>
*
* jquery-hover-init is currently available for use in all personal or commercial
* projects under both MIT and GPL licenses. This means that you can choose
* the license that best suits your project, and use it accordingly.
*
* @author    Doug Puchalski <doug316@gmail.com>
*/
(function($) {
  
	$.fn.hoverInitBind = function(func) {
    var elems = $j(this);
    return elems.bind('mouseenter', function(event) {
      return initHandler.call(this, event, func);
    });
  }

  $.fn.hoverInitLive = function(func) {
    var elems = $j(this);
    elems.each(function() { $(this).data('hover-init-live', true); });
    return elems.live('mouseenter', function(event) {
      return initHandler.call(this, event, func);
    });
  }

  function initHandler(event, func) {
    var elem = $(this);
    //console.log('hoverInit.initHandler', elem);

    var data = elem.data();
    var data = elem.data('hover-init-done');

    if (elem.data('hover-init-done')) return;
    //console.log('initHandler', elem, event);

    elem.data('hover-init-done', true);
    func.call(this, event);
    // If we're not using live, we can unbind the event and it won't be called again
    if (!elem.data('hover-init-live'))
      elem.unbind('mouseenter', initHandler);
  }

})(jQuery);

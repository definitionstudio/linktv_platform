/**
 * Admin functions, following singleton pattern.
 */

if (window.console && window.console.firebug) {
  // Firebug is enabled
  // Allow console.log/console.dir to execute
} else if (window.console) {
  if (!window.console.log)
    window.console.log = function() {};
  if (!window.console.dir)
    window.console.dir = function() {};
} else {
  // Define dummy stub functions
  window.console = {
    log: function() {},
    dir: function() {}
  }
}

$j(function() {
  Admin.init();
});

var Admin = {

  contentModified: false,

  init: function() {
    var doc = $j(document);

    // Delay to override
    setTimeout(function(){
      $j.extend($j.ui.dialog.defaults, {
      });
    });

    Admin.initEventHandlers();

    // Show-hide contexts
    doc.delegate('.show-hide-context a.show-control, .show-hide-context a.hide-control', 'click', function(event) {
      var elem = $j(this);
      if (elem.hasClass('show-control')) {
        // Show
        elem.parents('.show-hide-context:first').removeClass('state-hidden');
      } else {
        // Hide
        elem.parents('.show-hide-context:first').addClass('state-hidden');
      }
    });
  },
  
  /***
   * Install default form handlers.
   * These are generally installed using jQuery.delegate on the document, which means they bubble
   * up to the document before they are caught, and the selector is checked to see if it's a match.
   * This way, handlers can always be overridden by delegating or binding lower in the DOM tree,
   * closer to the element, or on the element itself.
   *
   * A new event flow is defined, with a standard flow, each event with a special purpose.
   *
   * 1. The click events for "buttons" are intercepted, and are triggered with operation-trigger.
   * 2. operation-trigger
   *    The event which invokes an operation. It checks for .state-disabled and
   *    aborts if it's set. Otherwise, it triggers operation-begin.
   *    This event can be triggered manually to invoke an operation, rather than click.
   * 3. operation-begin
   *    Sets .state-busy on the target element (i.e. button), and .state-disabled on
   *    both the target and its parent('.operation-context'). CSS can be then used to style the target
   *    and it's enclosing context as desired, as well as to disable any other buttons within the context.
   *    This event can be triggered manually to invoke an operation while ignoring .state-disabled.
   * 4. operation-handle
   *    This event should be bound to a target element to do the work of whatever operation is needed.
   *    By default, this event will bubble up to the form element, where it is bound to do a standard form.submit().
   *    In general, this event should be overridden to do ajax handling, or any other specific handling.
   * 5. operation-loaded
   *    Removes state-busy from the target, i.e. so the button will no longer display a loading state.
   *    This might be triggered by a dialog callback, for example, when its content has been loaded, such that
   *    the origial target would no longer appear busy. Then, if the dialog is cancelled, there won't be any
   *    lingering state in that original target.
   * 6. operation-cancel
   *    Should be triggered if an operation is cancelled, or if an error occurs.
   *    Removes .state-busy and .state-disable.
   *    Basically the same as operation-end with a different purpose.
   * 7. operation-end
   *    Should be triggered if an operation completes normally.
   *    Removes .state-busy and .state-disable.
   *    Basically the same as operation-cancel with a different purpose.
   *
   * Notes:
   * -  For anchor tags, .global-handler must be attached to bind the global event handlers.
   *    This is to allow normal links, without the class, to proceed as expected.
   *    TODO: probably add this class for button and input tags as well to be explicit and consistent.
   */
  initEventHandlers: function() {
    // Debug handlers
    $j(document).delegate('*', 'submit', function(event) {
      // Trap the event for debug, do not handle
      return true; // Proceed with other handlers
    });

    // Global button handlers
    // Adds .state-disabled when a button is clicked, to prevent multiple events.
    // Others should bind to the created "operation-handle" event which is triggered by this
    // handler as necessary.
    $j(document).delegate('a.button.global-handler, button.button, input.button[type="submit"]', 'click', function(event) {
      // This handler may be unbound and overridden by binding an event to the element and blocking the bubble.
      // Override should trigger operation-trigger
      var target = $j(this);
      target.trigger('operation-trigger');
      return false;

    }).delegate('a.button.global-handler, button.button, input.button[type="submit"]', 'operation-trigger', function(event) {
      var target = $j(this);

      if (target.hasClass('state-disabled') || target.parents('.operation-context:first').hasClass('state-disabled'))
        return false;
      target.trigger('operation-begin');
      return false;

    }).delegate('a.button.global-handler, button.button, input.button[type="submit"]', 'operation-begin', function(event) {
      // Event to begin an operation, marking the button busy
      // This event ignores state-disabled
      var target = $j(this);
      target.parents('.operation-context:first').andSelf().addClass('state-disabled');
      target.addClass('state-busy');
      target.trigger('operation-handle');
      return false;

    }).delegate('form', 'operation-handle', function(event) {
      // Default form handler just submits
      var target = $j(this);
      target.submit();
      return false;

    }).delegate('a.button.global-handler, button.button, input.button[type="submit"]', 'operation-loaded', function(event) {
      // Event to cancel any loading indidcators, but not re-enable the function
      var target = $j(this);
      target.removeClass('state-busy');
      return false;

    }).delegate('a.button.global-handler, button.button, input.button[type="submit"]', 'operation-cancel', function(event) {
      // Event to cancel an operation, marking the button available again
      var target = $j(this);
      target.parents('.operation-context:first').andSelf().removeClass('state-disabled');
      target.removeClass('state-busy');
      return false;

    }).delegate('a.button.global-handler, button.button, input.button[type="submit"]', 'operation-end', function(event) {
      // Event to end an operation, marking the button available again
      var target = $j(this);
      target.parents('.operation-context:first').andSelf().removeClass('state-disabled');
      target.removeClass('state-busy');
      return false;
    });

    // Trap forms with the .ajaxify class
    $j(document).delegate('form.ajaxify', 'submit', function(event) {
      var form = $j(this);
      setTimeout(function() {
        Admin.ajax({
          url: form.attr('action'),
          type: 'POST',
          data: form.serialize()
        });
      });
      return false;
    });
  },

  initInPlaceEdit: function(context, options) {
    options = $j.extend({}, options);

    context.delegate('.in-place-edit-context input', 'keypress', function(event) {
      var key = event.keyCode;
      if (key == 13) {
        var target = $j(this);
        var context = target.parents('.in-place-edit-context:first');
        context.find('a.in-place-edit-accept').click();
        return false;
      }
      return true;
    });

    context.delegate('.in-place-edit-context a', 'click', function(event) {
      // Note: for now we're assuming all anchor tags within .in-place-edit-context will be for the in-place-edit function
      // Seems safe enough, it's supposed to be a minimal context only for that purpose.
      var target = $j(this);
      var context = target.parents('.in-place-edit-context:first');
      var fields = $j('.in-place-edit-field', context);

      if (target.is('a.in-place-edit')) {
        
        // Begin edit
        context.addClass('in-place-edit-active');

        // Save current values
        fields.each(function() {
          field = $j(this);
          if (field.is('select')) {
            field.find('option').each(function() {
              var elem = $j(this);
              elem.data('previous-selected', elem.attr('selected'));
            });
          } else {
            field.data('previous-val', field.val());
          }
        });

        // Hidden selects are used for large datasets where we only want to show the included records
        if (context.hasClass('uses-hidden-select')) {

          // List of delete links for each selected item
          var deletableItemList = $j('.in-place-edit-deletable-item-list', context);
          var deletableItemListContent = $j('.content', deletableItemList);

          function addToDeletableItemList(id, value) {
            var object = $j($j.trim($j('.model', deletableItemList).html()));
            object.attr('data-id', id);
            object.find('.name').text(value);
            object.appendTo(deletableItemListContent);
          }

          // Fill in current values
          deletableItemListContent.text('');
          fields.find('option:selected').each(function() {
            var elem = $j(this);
            addToDeletableItemList(elem.val(), elem.text());
          });

          // Attach a function to add new options
          var select = context.find('select.hidden-select');
          select.unbind('addItem').bind('addItem', function(event, data) {
            select.append("<option selected=\"selected\" value=\"" + data.id + "\">" + data.value + "</option>");
            addToDeletableItemList(data.id, data.value);
          });

          // Handle deletions from list
          context.unbind('.hidden-select-delete');
          context.delegate('a.delete-option', 'click.hidden-select-delete', function(event) {
            var target = $j(this);
            setTimeout(function() {
              var object = target.parents('.object:first');
              var id = object.attr('data-id');
              select.find('option[value="' + id + '"]').attr('selected', false);
              object.remove();
            });
            return false;
          });

        }

        if (options.tinyMCESelector && fields.is(options.tinyMCESelector)) {
          fields.tinymce(options.tinyMCEOptions);
        }

        if (context.hasClass('image-uploader')) {
          if (!context.hasClass('image-uploader-init')) {
            // AJAX file uploads
            context.addClass('image-uploader-init');
            var thumb = context.find('.in-place-edit-value img');
            if (thumb.data('original-src') == null)
              thumb.data('original-src', thumb.attr('src'));
            var input = context.find('input.in-place-edit-field');
            new AjaxUpload(input.attr('id'), {
              action: '/admin/images',
              name: 'image',
              onSubmit: function(file, extension) {
                if (!extension.toLowerCase().match(/^jpe?g|png$/)) {
                  alert("Images must be JPEG or PNG.");
                  return false;
                }
                this.setData({
                  authenticity_token: $j(input[0].form).find('input[name="authenticity_token"]').val(),
                  filename: file
                });
                thumb.attr('src', null).addClass('ajax-loader');
              },
              onComplete: function(file, response) {
                var hash = $j(response).children('hash');
                if (hash.children('status').text() == 'success') {
                  thumb.removeClass('ajax-loader').attr('src', hash.children('src').text());
                  context.find('input.image-id').val(hash.children('id').text());
                }
              }
            });
          } else {
            context.find('input.image-id').attr('disabled', 'disabled');
            context.find('input.in-place-edit-field').attr('disabled', false);
          }
        }
        
      } else if (target.is('a.in-place-edit-accept')) {
        // Accept
        context.removeClass('in-place-edit-active');
        var val;
        if (fields.is('select')) {
          var names = [];
          $j('option:selected', fields).each(function() {names.push($j(this).text())});
          val = names.join(', ') || 'None';
          
        } else {
          val = fields.val();
        }

        if (context.hasClass('image-uploader')) {
          context.find('input.in-place-edit-field').attr('disabled', 'disabled');
          context.find('input.image-id').attr('disabled', false);
          var thumb = context.find('.in-place-edit-value img');
          thumb.data('original-src', thumb.attr('src'));

        } else if (context.hasClass('date-time')) {
          var dateStr = $j(fields[0]).val() + '-' + Admin.zeroPad($j(fields[1]).val(),2) + '-' + Admin.zeroPad($j(fields[2]).val(),2) +
            ' ' + $j(fields[3]).val() + ':' + $j(fields[4]).val() + ':00';
          $j('.in-place-edit-value', context).text(dateStr);
          
        } else if (options.tinyMCESelector && fields.is(options.tinyMCESelector)) {
          //tinyMCE.triggerSave();
          var html = fields.tinymce().getContent();
          $j('.in-place-edit-value', context).html(html);
          fields.val(html);
          tinyMCE.execCommand('mceRemoveControl', true, fields.attr('id'));
        } else {
          $j('.in-place-edit-value', context).text(val);
        }
        // Trigger an event for external listeners
        target.trigger('changed');

      } else if (target.is('a.in-place-edit-cancel')) {
        // Cancel
        context.removeClass('in-place-edit-active');

        if (context.hasClass('image-uploader')) {
          // Restore original image src
          var thumb = context.find('.in-place-edit-value img');
          thumb.attr('src', thumb.data('original-src'));
          // disable input value
          context.find('input.image-id').attr('disabled', 'disabled');
          
        } else if (options.tinyMCESelector && fields.is(options.tinyMCESelector)) {
          tinyMCE.execCommand('mceRemoveControl', true, fields.attr('id'));
        }

        fields.each(function() {
          if (field.is('select')) {
            field.find('option').each(function() {
              var elem = $j(this);
              elem.attr('selected', elem.data('previous-selected'))
            });
          } else {
            field.val(field.data('previous-val'));
          }
        });
      }
    });
  },

  qtipDefaults: {
    style: {
      name: 'cream',
      width: 500,
      padding: 10,
      tip: 'leftMiddle'
    },
    position: {
      corner: {
        target: 'rightMiddle',
        tooltip: 'leftMiddle'
      }
    }
  },

  /**
   * Global ajax handler.
   *
   * Options:
   *   TODO
   *   - target: selector for destination of content being loaded.
   *     Will have .state-ajax-loading class added to it while the operation is in progress.
   *     If data.html element is returned in JSON, will replace existing target content.
   *   - preprocessHtml(html): function to be called on data.html before it replaces
   *     the target. See option.target.
   */
  ajax: function(options) {
      options = $j.extend({
      
      // Defaults
      successJsEval: true, // Execute javascript if returned for success
      errorJsEval: false, // Execute javascript if returned for error
      complete: options.complete,

      // TODO: successJson and errorJson handlers might be able to be merged.
      successJson: function(data, textStatus, xhr) {
        if (data.status != 'success' && data.msg) {
          var msg = "There was a problem communicating with the server.";
          msg += " Message: " + data.msg;
          alert(msg);
          return;
        }

        if (data.redirect_url) {
          window.location = data.redirect_url;
          return;
        }

        if (data.replace) {
          $j.each(data.replace, function(key) {
            alert('todo');
            console.log(data, key, this);
          });
        }

        if (options.target && data.html) {
          var target = $j(options.target).removeClass('state-ajax-loading');
          var content = target.find('.content');
          if (content.length == 0) content = target;
          var html = data.html;
          // Select a sub-element of the response
          var obj = $j(html);
          if (options.targetSelector)
            // If specified, extract content from given selector
            html = obj.find(options.targetSelector).html();
          else {
            // If present, extract content from .ajax-response-container
            var responseContainer = $j('.ajax-response-container', obj);
            if (responseContainer.count == 1)
              html = responseContainer.html();
          }
          if ($j.isFunction(options.preprocessHtml))
            html = options.preprocessHtml(html);
          content.html(html);
        }

        if (data.js) {
          eval(data.js);
        }
      },


      errorJson: function(xhr, textStatus, errorThrown) {
        var data = $j.parseJSON(xhr.responseText);

        if (data.status != 'success' && data.msg) {
          var msg = "There was a problem communicating with the server.";
          msg += " Message: " + data.msg;
          alert(msg);
          return;
        }
        
        if (data.js) {
          eval(data.js);
          return;
        }

        if (data.redirect_url) {
          window.location = data.redirect_url;
          return;
        }

        var msg = "There was a problem communicating with the server.";
        if (data.msg)
          msg += " Message: " + data.msg;
        alert(msg);
      },
      
      // Retain references to incoming callbacks that will be redefined
      incomingError: options.error,
      incomingSuccess: options.success

    }, options, {
      
      // Overrides
      success: function(data, textStatus, xhr) {
        var contentType = xhr.getResponseHeader('Content-Type') || '';
        if (!contentType) return; // Must have been interrupted

        if ($j.isFunction(options.incomingSuccess))
            options.incomingSuccess(data, textStatus, xhr);

        if (contentType.match('^text/html;')) {
          if ($j.isFunction(options.successHtml))
            options.successHtml(data, textStatus, xhr);

        } else if (contentType.match('^application/json;')) {
          if ($j.isFunction(options.successJson))
            options.successJson(data, textStatus, xhr);

        } else if (contentType.match('^text/javascript;')) {
          if ($j.isFunction(options.successJs))
            options.successJs(data, textStatus, xhr);
          else if (options.successJsEval)
            eval(xhr.responseText);
        }

        if ($j.isFunction(options.afterSuccess))
          options.afterSuccess(data, textStatus, xhr);

        if (options.trigger)
          options.trigger.trigger('operation-end');
      },
      
      error: function(xhr, textStatus, errorThrown) {
        var contentType = xhr.getResponseHeader('Content-Type');
        if (!contentType) return; // Must have been interrupted

        if ($j.isFunction(options.incomingError))
            options.incomingError(xhr, textStatus, errorThrown);

        if (contentType.match('^text/html;')) {
          if ($j.isFunction(options.errorHtml))
            options.errorHtml(xhr, textStatus, errorThrown);
          else {
            // Default: On error, replace the page contents with the error, for ease of debug
            var html = xhr.responseText;
            $j(document).find('head').html(html.replace('<head>(.*)</head>', '$1'));
            $j(document).find('body').html(html.replace('<body>(.*)</body>', '$1'));
            window.scroll(0, 0);
          }

        } else if (contentType.match('^application/json;')) {
          if ($j.isFunction(options.errorJson))
            options.errorJson(xhr, textStatus, errorThrown);

        } else if (contentType.match('^text/javascript;')) {
          if ($j.isFunction(options.errorJs))
            options.errorJs(xhr, textStatus, errorThrown);
          else if (options.errorJsEval)
            eval(xhr.responseText);
        }

        if ($j.isFunction(options.afterError))
          options.afterError(xhr, textStatus, errorThrown);

        if (options.trigger)
          options.trigger.trigger('operation-cancel');

      }

    });

    if (options.target)
      $j(options.target).addClass('state-ajax-loading');

    result = $j.ajax(options);
    return result;
  },

  dialog: function(options) {

    var dialog; // Will be reassigned if dialog content is replaced
    var origDialogOptions = options;
    var dialogOptions = $j.extend({
      // Defaults
    }, origDialogOptions, {
      // Overrides
      // Null-out options that are meant for the initial ajax load
      type: null,
      url: null,
      data: null,
      open: function(event) {
        dialog = $j(event.target);

        function contentChange() {
          dialog.dialog('option', 'position', 'center');
        }

        function afterLoad() {
          if ($j.isFunction(origDialogOptions.afterOpen))
            origDialogOptions.afterOpen(event);
          contentChange();
          if (origDialogOptions.ajaxFormHandler) {
            dialog.attachAjaxFormHandler($j.extend(origDialogOptions.ajaxFormHandler, {
              afterContentChange: contentChange
            }));
          }
          dialog.delegate('button.cancel', 'click', function(event) {
            setTimeout(function() {
              dialog.dialog('close');
              if (origDialogOptions.event)
                 $j(origDialogOptions.event.target).trigger('operation-cancel');
            });
            return false;
          });
        }

        if (origDialogOptions.html) {
          dialog.find('.content').html(origDialogOptions.html);
          afterLoad();
        } else if (origDialogOptions.url) {
          function success(data, textStatus, xhr) {
            afterLoad();
          }
          
          Admin.ajax({
            type: origDialogOptions.type || 'GET',
            url: origDialogOptions.url,
            data: origDialogOptions.data,
            dataType: 'json',
            success: success,
            successJson: function(data, textStatus, xhr) {
              dialog.removeClass('state-ajax-loading').find('.content').html(data.html);
              success(data, textStatus, xhr);
            },
            errorJson: function(xhr, textStatus, errorThrown) {
              // Override the default ajax errorJson handler so we can remove the dialog
              dialog.remove();
              $j(origDialogOptions.event.target).trigger('operation-cancel');

              var data = $j.parseJSON(xhr.responseText);
              if (data.js) {
                eval(data.js);
                return;
              }

              var msg = "There was a problem communicating with the server.";
              if (data.msg)
                msg += " Message: " + data.msg;
              alert(msg);
            }
          });
        }
      },
      close: function(event) {
        // Note: might need to pass state to callback whether the content was loaded or not
        if (origDialogOptions.event)
          $j(origDialogOptions.event.target).trigger('operation-end');
        if ($j.isFunction(origDialogOptions.beforeClose))
          origDialogOptions.beforeClose(event);
        dialog.remove();
      }
    });

    var html;
    if (options.html) {
      html = options.html;
      $j(html).dialog(dialogOptions);
    } else {
      // Open dialog with loading indicator
      html = "<div><div class=\"ajax-loading\">" + Admin.loadingIndicatorHtml() + "</div><div class=\"content\"/></div>";
      $j(html).dialog(dialogOptions).addClass('state-ajax-loading');
    }
  },

  loadingIndicatorHtml: function() {
    return "<p class=\"ajax-loader\">Loading...</p>";
  },

  zeroPad: function(number, length) {
    var str = '' + number;
    while (str.length < length) {
      str = '0' + str;
    }
    return str;
  },

  setContentModified: function() {
    if(!Admin.contentModified) {
      Admin.contentModified = true;
      window.onbeforeunload = function(e) {
        e = e || window.event;
        // For IE and Firefox prior to version 4
        if (e) e.returnValue = 'You may have unsaved changes.';
        // all others
        return 'You may have unsaved changes.';
      };
    }
  },

  clearContentModified: function() {
    Admin.contentModified = false;
    window.onbeforeunload = function() {};
  }

}

$j.fn.attachAjaxFormHandler = function(options) {
  var context = $j(this);

  var afterLoad = function() {
    if ($j.isFunction(options.afterLoad))
      options.afterLoad();
    if ($j.isFunction(options.afterContentChange))
      options.afterContentChange();
  }

  var forms = $j(options.formSelector, context);
  forms.each(function() {
    var form = $j(this);
    form.bind('submit', function(event) {
      setTimeout(function() {
        if ($j.isFunction(options.beforeSubmit)) {
          if (!options.beforeSubmit()) {
            $j(event.target).trigger('operation-cancel');
            return false;
          }
        }

        var data = form.serialize();
        if (options.data)
          data += '&' + $j.param(options.data);

        var ajaxOptions = $j.extend({
          // Defaults
          type: 'POST',
          url: form.attr('action'),
          data: data,
          dataType: options.dataType || 'json',
          successJsEval: options.successJsEval,
          errorJsEval: options.errorJsEval,
          error: function(xhr, textStatus, errorThrown) {
            // Probably means validation failed
            context.empty();
            var contentType = xhr.getResponseHeader('Content-Type');
            if (!contentType) return; // Must have been interrupted
            if (contentType.match('^text/html;')) {
              context.html(xhr.responseText);
            } else if (contentType.match('^application/json;')) {
              data = $j.parseJSON(xhr.responseText);
              if (data && data.html)
                context.html(data.html);
            }
            if ($j.isFunction(options.contentInit))
              options.contentInit();
            context.attachAjaxFormHandler(options);
            afterLoad();
          }
        }, options.ajaxOptions, {
          // Overrides
        });

        Admin.ajax(ajaxOptions);
        return false;
      });
      return false;
    });
  });
};
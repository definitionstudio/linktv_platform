var Topics = (function() {

  return {
    
    newTopicInit: function(context, options) {
      var self = this;

      var contentChange = function() {
        if ($j.isFunction(options.afterContentChange))
          options.afterContentChange();
      }

      var contentInit = function() {

        function setIdentifier(context, name, identifier) {
          $j('input.entity-identifier', context).val(identifier).attr('disabled', false);
          $j('input.topic_name', context).val(name);
        }

        // Freebase suggest API
        $j('#freebase_name', context).filter('.do-init').removeClass('do-init').suggest({
            zIndex: 9999
        }).bind('fb-select', function(event, data) {
          // Name form field is set automatically by the suggest call
          setIdentifier($j(this).parents('.object-entity-db'), data.name, data.id);
        });

        // dbPedia autocomplete lookup via server proxy
        var topicName = $j('.object-entity-db.disambiguator-dbpedia input.topic-name', context);
        var entityDb = topicName.parents('.object-entity-db');
        topicName.filter('.do-init').removeClass('do-init').autocomplete({
          source: function(request, response) {
            $j.ajax({
              url: '/admin/entity_dbs/' + entityDb.attr('data-id') + '/autocomplete',
              dataType: "json",
              data: {
                q: request.term
              },
              success: function(data) {
                response($j.map(data.data, function(item) {
                  return {
                    label: "<span " + 
                      "title=\"" + item.description.replace(/"/, '\\"') + "\" " +
                      "data-identifier=\"" + item.identifier + "\">" +
                      item.label + '</span>',
                    value: item.label
                  }
                }));
              }
            });
          },
          select: function(event, ui) {
            var item = $j(ui.item.label);
            $j('input.entity-db-id', entityDb).attr('disabled', false);
            setIdentifier(entityDb, item.text(), item.attr('data-identifier'));
          }
        });
      }

      var topicName = $j('input.topic-name', context);

      // set focus
      topicName.focus();

      if (options.showExistingTopics) {
        // Matching topic autocomplete
        var topicNameTimeout = null;
        var topicMinSearchLength = 2;
        var lastTopicName = null;
        var timeout = 700;
        function topicNameHandler() {
          // Update the matching topics
          var currentTopicName = $j.trim(topicName.val());
          if (currentTopicName == lastTopicName) return;
          if(currentTopicName.length < topicMinSearchLength) return;
          var matchingTopics = context.find('.matching-topics');
          matchingTopics.addClass('state-ajax-loading');
          Admin.ajax({
            url: '/admin/topics/matching',
            data: $j.extend(options.data, {
              name: currentTopicName
            }),
            target: matchingTopics
          });
        }
        function topicNameChange() {
          // Unlink the identifier in case it was previously linked (via disambigutation)
          context.parents('.object-entity-db-id').find('input.entity-db-id, input.entity-identifier').attr('disabled', true);
        }
        topicName.bind('keypress', function() {
          clearTimeout(topicNameTimeout);
          topicNameTimeout = setTimeout(topicNameHandler, timeout);
          topicNameChange();
        }).change(function() {
          topicNameChange();
        });
      }

      context.delegate('a.add-disambiguation', 'click', function(event) {
        event.preventDefault();
        var target = $j(this);
        var select = target.siblings('.entity-db-id');
        var entityDbId = select.val();
        var entityDb = $j('.disambiguator-entity-db-id-' + entityDbId, context);
        // Copy the pre-entered topic name in the disambiguator
        $j('input.topic-name', entityDb).val(topicName.val());
        entityDb.find('input').attr('disabled', false);
        entityDb.show();
        // Remove option from select
        $j('option[value="' + entityDbId + '"]').remove();
        contentChange();

        // Trigger the control if necessary
        if (entityDb.hasClass('disambiguator-freebase')) {
          $j('input.topic-name', context).trigger('textchange');
        } else if (entityDb.hasClass('disambiguator-dbpedia')) {
          $j('input.topic-name', context).autocomplete('search');
        }
        return false;
      });

      context.delegate('a.delete-disambiguation', 'click', function(event) {
        event.preventDefault();
        var elem = $j(this);
        var entityDb = elem.parents('.object-entity-db:first');
        if (parseInt(entityDb.find('input.entity-id').val()) > 0) {
          entityDb.find('input.entity-destroy').val(1);
        } else {
          entityDb.find('input').attr('disabled', true);
        }
        entityDb.hide();
        return false;
      });

      // Existing topic/create new topic radio button handling
      context.delegate('.topic-chooser input[name="topic_id"]', 'change', function() {
        var val = $j('.topic-chooser input[name="topic_id"]:checked', context).val();
        if (val) {
          context.find('.object-add-new-topic').removeClass('state-new-topic');
        } else {
          context.find('.object-add-new-topic').addClass('state-new-topic');
        }
        contentChange();
      });

      contentInit();
      Entities.initEntityLinks(context);

      if (options.attachAjaxFormHandler) {
        // Handle form submission via AJAX
        context.attachAjaxFormHandler({
          formSelector: 'form',
          contentInit: contentInit,
          successJsEval: options.successJsEval,
          errorJsEval: options.errorJsEval,
          beforeSubmit: function() {
            var topic = $j('input[name="topic_id"]:checked', context);
            var topicId = topic && topic.val();
            var topicName = $j.trim($j('input[name="topic[name]"]', context).val());
            if (topic.length == 0 || topicId == '') {
              if (topicName == '') {
                setTimeout(function() {
                  // Delay to allow callbacks to proceed to update button state
                  alert('A topic name is required');
                });
                return false;
              }
              // Creating a new topic
              return true; // Submit form
            } else {
              // Selected an existing topic
              options.selectExistingTopic(topic.siblings('label:first').find('.segment-topic-template'));
              return false; // Don't submit form
            }
          },
          ajaxOptions: {
            dataType: options.dataType,
            successJson: function(data, textStatus, xhr) {
              var template = $j(data.html);
              if ($j.isFunction(options.afterCreate))
                options.afterCreate(template);
            }
          }
        });
      }
    },

    /**
     * Open a dialog to create a new topic.
     */
    newTopicDialog: function(data, options) {
      options = $j.extend({}, options);
      var dialog;

      Admin.dialog({
        event: options.event,
        title: 'Add New Topic',
        url: options.url, // || '/admin/topics/new',
        data: data,
        modal: true,
        width: 'auto',
        beforeClose: function(event) {
          // .fbs-reset ensures the freebase.suggest elements can be recreated, without getting stuck having an old parent (this dialog)
          $j(event.target).find('.fbs-reset').remove();
        },
        afterOpen: function(event) {
          dialog = $j(event.target);
          var uiDialog = dialog.parents('.ui-dialog:first');
          var topic = Topics.newTopicInit(dialog, {
            showExistingTopics: true,
            existing_topics: data.existing_topics,
            attachAjaxFormHandler: options.attachAjaxFormHandler,
            afterContentChange: function() {
              dialog.dialog('option', 'position', 'center');
            },
            afterCreate: function(template) {
              dialog.dialog('close');
              if ($j.isFunction(options.afterCreate))
                options.afterCreate(template);
              if (options.event)
                $j(options.event.target).trigger('operation-end');
            },
            selectExistingTopic: function(template) {
              dialog.dialog('close');
              if ($j.isFunction(options.selectExistingTopic))
                options.selectExistingTopic(template);
              if (options.event)
                $j(options.event.target).trigger('operation-end');
            }
          });

          if (options.event)
            $j(options.event.target).trigger('operation-loaded');
        },
        complete: options.complete
      });

    },

    /**
     * Create a topic with the supplied form data.
     */
    createTopic: function(data, options) {
      Admin.ajax({
        type: 'POST',
        url: options.url || '/admin/topics',
        dataType: 'json',
        data: data,
        successJson: function(data, textStatus, xhr) {
          if ($j.isFunction(options.afterCreate))
            options.afterCreate($j(data.html));
        }
      });
    }
  }
})();

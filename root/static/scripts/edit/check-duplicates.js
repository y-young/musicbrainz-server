// This file is part of MusicBrainz, the open internet music database.
// Copyright (C) 2015 MetaBrainz Foundation
// Licensed under the GPL version 2, or (at your option) any later version:
// http://www.gnu.org/licenses/gpl-2.0.txt

var _ = require('lodash');
var ko = require('knockout');
var React = require('react');
var i18n = require('../common/i18n');
var clean = require('../common/utility/clean');
var isBlank = require('../common/utility/isBlank');
var request = require('../common/utility/request');
var validation = require('./validation');
var PossibleDuplicates = require('./components/PossibleDuplicates');

var commentRequired = ko.observable(false);
var commentEmpty = ko.observable(false);

validation.errorField(ko.computed(function () {
  return commentRequired() && commentEmpty();
}));

var needsConfirmation = ko.observable(false);
var isConfirmed = ko.observable(false);

validation.errorField(ko.computed(function () {
  return needsConfirmation() && !isConfirmed();
}));

var requestPending = validation.errorField(ko.observable(false));

function renderDuplicates(name, duplicates, container) {
  needsConfirmation(true);

  React.render(
    <PossibleDuplicates
      name={name}
      duplicates={duplicates}
      checkboxCallback={event => isConfirmed(event.target.checked)} />,
    container
  );
}

function unmountDuplicates(container) {
  needsConfirmation(false);
  React.unmountComponentAtNode(container);
}

function sortPlaceDuplicates(duplicates) {
  var selectedArea = ko.unwrap(getSelectedArea()) || {};

  function sharesLevel(area, level) {
    return (
      (area[`parent_${level}`] || area).gid ===
      (selectedArea[`parent_${level}`] || selectedArea).gid
    );
  }

  return _.sortBy(duplicates, function (dupe) {
    var area = dupe.area;

    if (!area) {
      return 0;
    }

    if (area.gid === selectedArea.gid) {
      return 1;
    }

    if (area.name === selectedArea.name) {
      return 2;
    }

    if (sharesLevel(area, 'city')) {
      return 3;
    }

    if (sharesLevel(area, 'subdivision')) {
      return 4;
    }

    if (sharesLevel(area, 'country')) {
      return 5;
    }

    return 6;
  });
}

function sortDuplicates(type, duplicates) {
  if (type === 'place') {
    return sortPlaceDuplicates(duplicates);
  }

  return duplicates;
}

function getSelectedArea() {
  return $('span.area.autocomplete > input.name').data('ui-autocomplete').currentSelection;
}

function isPlaceCommentRequired(duplicates) {
  var selectedArea = ko.unwrap(getSelectedArea()) || {};

  // We require a disambiguation comment if no area is given, or if there
  // is a possible duplicate in the same area or lacking area information.
  if (!selectedArea.gid) {
    return true;
  }

  return _.any(duplicates, function (place) {
    return !place.area || place.area.gid === selectedArea.gid;
  });
}

function isCommentRequired(type, duplicates) {
  if (type === 'place') {
    return isPlaceCommentRequired(duplicates);
  }

  return duplicates.length > 0;
}

function markCommentAsRequired(input) {
  commentRequired(true);

  var $parent = $(input)
    .attr('required', 'required')
    .addClass('error')
    .parent();

  if (!$parent.next('div.comment-required').length) {
    $parent.after($('<div>').addClass('no-label error comment-required').text(i18n.l('Required field.')));
  }
}

function markCommentAsNotRequired(input) {
  commentRequired(false);

  $(input)
    .removeAttr('required')
    .removeClass('error')
    .parent()
    .next('div.comment-required')
    .remove();
}

MB.initializeDuplicateChecker = function (type) {
  var nameInput = document.getElementById(`id-edit-${type}.name`);
  var commentInput = document.getElementById(`id-edit-${type}.comment`);
  var dupeContainer = document.getElementById('possible-duplicates');
  var currentName = nameInput.value;
  var originalName = currentName;
  var currentDuplicates = [];
  var promise;

  function makeRequest(name, forceRequest) {
    var nameChanged = name !== originalName;

    // forceRequest only applies if name is non-empty.
    // we should never check for duplicates of an existing entity, if the name hasn't changed.
    if (isBlank(name) || !(nameChanged || forceRequest) || (MB.sourceEntityGID && !nameChanged)) {
      unmountDuplicates(dupeContainer);
      markCommentAsNotRequired(commentInput);
      return;
    }

    requestPending(true);
    promise = request({
        url: '/ws/js/check_duplicates',
        data: $.param({type: type, name: name, mbid: MB.sourceEntityGID}, true)
      })
      .done(function (data) {
        var duplicates = sortDuplicates(type, data.duplicates);

        if (duplicates.length) {
          renderDuplicates(name, duplicates, dupeContainer);

          if (isBlank(commentInput.value) && isCommentRequired(type, duplicates)) {
            markCommentAsRequired(commentInput);
          }
        } else {
          unmountDuplicates(dupeContainer);
          markCommentAsNotRequired(commentInput);
        }

        currentDuplicates = duplicates;
      })
      .fail(function (jqXHR) {
        if (/^50/.test(jqXHR.status)) {
          _.delay(_.partial(makeRequest, name, false), 3000);
        }
      })
      .always(function () {
        promise = null;
        requestPending(false);
      });
  }

  function normalize(name) {
    return clean(name).toLowerCase();
  }

  var handleNameChange = _.debounce(function (name, forceRequest) {
    if (forceRequest || normalize(name) !== normalize(currentName)) {
      if (promise) {
        promise.abort();
      }
      makeRequest(name, forceRequest);
      currentName = name;
    }
  }, 300);

  // Initiate the duplicate checker on the existing name, which may have been
  // seeded via query parameters.
  handleNameChange(currentName, true);
  $(nameInput).on('input', function () {
    handleNameChange(this.value, false);
  });

  function checkForEmptyComment() {
    commentEmpty(isBlank(this.value));
  }

  checkForEmptyComment.call(commentInput);
  $(commentInput).on('input', checkForEmptyComment);

  if (type === 'place') {
    getSelectedArea().subscribe(function () {
      if (currentDuplicates.length && isPlaceCommentRequired(currentDuplicates)) {
        markCommentAsRequired(commentInput);
      } else {
        markCommentAsNotRequired(commentInput);
      }
    });
  }
};

module.exports = MB.initializeDuplicateChecker;

// Copyright (c) 2016 Kristoffer Gronlund <kgronlund@suse.com>
// See COPYING for license.

(function($) {
  'use strict';

  function fa(name) {
    return '<i class="fa fa-' + name + '"></i>';
  }

  function unit_in_timespan(h, min_time, timespan) {
    var s = min_time - (min_time % h);
    var r = [s];
    while (s < min_time + timespan) {
      s += h;
      if (s >= min_time && s <= min_time + timespan) {
        r.push(s);
      }
    }
    if (r.length == 0) {
      r.push(min_time);
    }
    if (r.length > 12) {
      r = r.slice(0, 12);
    }
    return r;
  }

  var MIN_SPAN = 10000;
  var MAX_SPAN = 1000 * 3600 * 24 * 365 * 100;

  var EventControl = function(element, options) {

    this.settings = $.extend({
      onhover: function(item, element, event, inout) {},
      onclick: function(item, element, event) {},
      oncreate: function(item, element) {},
      data: [],
    }, options);

    this.element = element;
    this.width = element.width();

    this.items_h = (6*8) + 4;
    this.markers_h = 31;
    this._dragging = null;
    this._drag_x = 0;

    element.append(['<div class="ec-items ec-draggable" style="top:0px;height:', this.items_h, 'px;"></div>',
                    '<div class="ec-markers ec-draggable" style="top:', (this.items_h + 1), 'px;height:', this.markers_h, 'px;">',
                    '<div class="ec-ticks"></div>',
                    '<div class="ec-labels"></div>',
                    '</div>'
                   ].join(''));

    this.items = element.children('.ec-items');
    this.markers = element.children('.ec-markers');
    this.ticks = this.markers.children('.ec-ticks');
    this.labels = this.markers.children('.ec-labels');
    this.min_time = moment("2070-01-01");
    this.max_time = moment("1970-01-01");
    this.timespan = MAX_SPAN;
    this.max_timespan = MAX_SPAN;
    this.center_time = this.min_time.valueOf() + MAX_SPAN * 0.5;

    this.init();

    return this;
  };

  EventControl.prototype.init = function() {
    var self = this;
    var element = this.element;

    element.on('click', function(e) {
      var tgt = $(e.target);
      if (tgt.hasClass('ec-dot')) {
        self.settings.onclick.call(self, tgt.data('event'), tgt, e);
      }
    });

    element.mousedown(function(e) {
      if (e.which == 1) {
        element.children('.ec-draggable').addClass('ec-dragging');
        self._dragging = true;
        self._drag_x = e.pageX;
        self._drag_min_time = self.min_time.valueOf();
        self._drag_max_time = self.max_time.valueOf();
        return false;
      }
    });

    function stop_dragging() {
      element.children('.ec-draggable').removeClass('ec-dragging');
      self._dragging = null;
    }

    $('body').mouseup(function(e) {
      if (e.which == 1) {
        stop_dragging();
      }
    });

    $('body').on("dragend",function(){
      stop_dragging();
    });

    $(window).resize(function() {
      if (!self._dirty) {
        self._dirty = true;
        if (self.min_time && self.max_time) {
          var mit = self.min_time.clone();
          var mat = self.max_time.clone();
          window.setTimeout(function() {
            if (mit.isSame(self.min_time) && mat.isSame(self.max_time)) {
              self.update_timespan(mit, mat);
            }
          }, 400);
        }
      }
    });

    $('body').mousemove(function(e) {
      if (e.which == 1 && self._dragging) {
        var deltapx = -(e.pageX - self._drag_x);
        deltapx = deltapx - (deltapx % 4);
        var dragdelta = deltapx / self.width;

        if (dragdelta > 0.9)
          dragdelta = 0.9;
        else if (dragdelta < -0.9)
          dragdelta = -0.9;

        var time_offset = dragdelta * self.timespan;

        var new_min_time = moment(self._drag_min_time + time_offset);
        var new_max_time = moment(self._drag_max_time + time_offset);
        if (!new_min_time.isSame(self.min_time) || new_max_time.isSame(self.max_time)) {
          self.update_timespan(new_min_time, new_max_time);
        }
      }
    });

    element.on('mousewheel', function(event) {
      event.preventDefault();
      var dir = event.deltaY;
      // factor = event.deltaFactor;

      var base = element.offset();

      var offset = (event.pageX - base.left) / self.width;

      var new_min_time = self.min_time.clone();
      var new_max_time = self.max_time.clone();

      if (dir < 0) {
        var delta = self.timespan * 0.5;
        new_min_time.subtract(delta * offset, 'milliseconds');
        new_max_time.add(delta * (1.0 - offset), 'milliseconds');
      } else {
        var delta = self.timespan * 0.25;
        new_min_time.add(delta * offset, 'milliseconds');
        new_max_time.subtract(delta * (1.0 - offset), 'milliseconds');
      }

      self.update_timespan(new_min_time, new_max_time);
    });

    $.each(self.settings.data, function(i, item) {
      self.items.append('<div class="ec-dot" style="left:0px;top:0px;"></div>');
      var elem = self.items.children('.ec-dot').last();
      elem.data('event', item);
      item._starttime = moment(item.timestamp).valueOf();

      self.settings.oncreate.call(self, item, elem);

      elem.hover(function(event) {
        self.settings.onhover.call(self, item, elem, event, 'in');
      }, function(event) {
        self.settings.onhover.call(self, item, elem, event, 'out');
      });

      var t = moment(item.timestamp);
      if (t < self.min_time) {
        self.min_time = t.clone();
      }
      if (t > self.max_time) {
        self.max_time = t;
      }
    });

    self.min_time.subtract(5, 'seconds');
    self.max_time.add(5, 'seconds');
    self.center_time = self.min_time.valueOf() + (self.max_time.valueOf() - self.min_time.valueOf()) * 0.5;

    self.update_timespan(self.min_time.clone(), self.max_time.clone());
  };

  EventControl.prototype.save_state = function() {
    return {min_time: this.min_time.valueOf(), max_time: this.max_time.valueOf()};
  };

  EventControl.prototype.load_state = function(state) {
    this.update_timespan(state.min_time, state.max_time);
  };

  EventControl.prototype.update_timespan = function(new_min_time, new_max_time) {
    var self = this;
    var element = this.element;

    self._dirty = false;
    self.width = element.width();

    self.ticks.empty();
    self.labels.empty();

    if (!moment.isMoment(new_min_time)) {
      new_min_time = moment(new_min_time);
    }
    if (!moment.isMoment(new_max_time)) {
      new_max_time = moment(new_max_time);
    }

    self.timespan = new_max_time.valueOf() - new_min_time.valueOf();
    if (self.timespan < MIN_SPAN) {
      var ct = self.min_time.valueOf() + (self.max_time.valueOf() - self.min_time.valueOf()) * 0.5;
      new_min_time = moment(ct - MIN_SPAN*0.5);
      new_max_time = moment(ct + MIN_SPAN*0.5);
      self.timespan = new_max_time.valueOf() - new_min_time.valueOf();
    }

    if (self.max_timespan == MAX_SPAN) {
      self.max_timespan = self.timespan * 2;
    }

    if (self.timespan > self.max_timespan) {
      new_min_time = moment(self.center_time - self.max_timespan * 0.5);
      new_max_time = moment(self.center_time + self.max_timespan * 0.5);
      self.timespan = self.max_time.valueOf() - self.min_time.valueOf();
    }
    self.min_time = new_min_time;
    self.max_time = new_max_time;

    var min_time_ms = self.min_time.valueOf();

    var major;
    var minor;
    var major_fmt = 'YYYY-MM-DD';
    var minor_fmt = 'HH:mm';
    var maj_unit = 24*3600*1000;
    var min_unit = 24*3600*1000;

    if (self.timespan > 365*24*3600*1000) {
      maj_unit = 120*24*3600*1000;
      major_fmt = 'YYYY-MM';
      min_unit = null;
    } else if (self.timespan > 120*24*3600*1000) {
      maj_unit = 31*24*3600*1000;
      major_fmt = 'YYYY-MM';
      min_unit = null;
    } else if (self.timespan > 31*24*3600*1000) {
      maj_unit = 31*24*3600*1000;
      min_unit = null;
    } else if (self.timespan > 24*24*3600*1000) {
      maj_unit = 14*24*3600*1000;
      min_unit = null;
    } else if (self.timespan > 12*24*3600*1000) {
      maj_unit = 7*24*3600*1000;
      min_unit = null;
    }

    if (self.timespan < 6*24*3600*1000) {
      min_unit = 12*3600*1000;
    }

    if (self.timespan < 3*24*3600*1000) {
      min_unit = 6*3600*1000;
    }

    if (self.timespan < 3*24*3600*1000) {
      min_unit = 6*3600*1000;
    }

    if (self.timespan < 2*24*3600*1000) {
      min_unit = 3*3600*1000;
    }

    if (self.timespan < 24*3600*1000) {
      min_unit = 3*3600*1000;
    }

    if (self.timespan < 12*3600*1000) {
      min_unit = 3600*1000;
    }

    if (self.timespan < 6*3600*1000) {
      min_unit = 30*60*1000;
    }

    if (self.timespan < 3*3600*1000) {
      min_unit = 15*60*1000;
    }

    if (self.timespan < 3600*1000) {
      min_unit = 5*60*1000;
    }

    if (self.timespan < 45*60*1000) {
      min_unit = 4*60*1000;
    }

    if (self.timespan < 30*60*1000) {
      min_unit = 3*60*1000;
    }

    if (self.timespan < 20*60*1000) {
      min_unit = 2*60*1000;
    }

    if (self.timespan < 10*60*1000) {
      min_unit = 60*1000;
    }

    if (self.timespan < 5*60*1000) {
      min_unit = 30*1000;
    }

    if (self.timespan < 2*60*1000) {
      min_unit = 15*1000;
    }

    if (self.timespan < 60*1000) {
      min_unit = 10*1000;
    }

    if (self.timespan < 45*1000) {
      min_unit = 5*1000;
    }

    if (self.timespan < 20*1000) {
      min_unit = 2*1000;
    }

    if (self.timespan < 12*1000) {
      min_unit = 1*1000;
    }

    major = unit_in_timespan(maj_unit, min_time_ms, self.timespan);

    if (min_unit != null) {
      if (min_unit < 60*1000) {
        minor_fmt = 'HH:mm:ss';
      }

      minor = unit_in_timespan(min_unit, min_time_ms, self.timespan);

      $.each(minor, function(i, ts) {
        var xoffs = (self.width / self.timespan) * (ts - min_time_ms);
        self.ticks.append(['<div class="ec-tick" style="left:', xoffs, 'px;top:', 1, 'px;height:', self.items_h + 1 + self.markers_h, 'px;"></div>'].join(''));

        var l = (self.width / self.timespan) * (ts - min_time_ms);
        var t = self.items_h + 1;
        var lbl = moment(ts).format(minor_fmt);
        self.labels.append(['<div class="ec-label" style="left:', l, 'px;top:', t, 'px;">', lbl, '</div>'].join(""));
      });
    } else {
      $.each(major, function(i, ts) {
        var xoffs = (self.width / self.timespan) * (ts - min_time_ms);
        self.ticks.append(['<div class="ec-tick" style="left:', xoffs, 'px;top:', 1, 'px;height:', self.items_h * 0.5, 'px;"></div>'].join(''));
      });
    }

    $.each(major, function(i, ts) {
      var l = ((self.width - 4) / self.timespan) * (ts - min_time_ms) + 2;
      var t = self.items_h + self.markers_h - 14;
      var lbl = moment(ts).format(major_fmt);
      if (l < 0) {
        if (i < major.length-1) {
          var next = ((self.width - 4) / self.timespan) * (major[i + 1] - min_time_ms) + 2;
          if (next > 60) {
            l = 2;
          }
        } else {
          l = 2;
        }
      }

      self.labels.append(['<div class="ec-region-label" style="left:', l, 'px;top:', t, 'px;">', lbl, '</div>'].join(""));
    });

    var item_offset = 2;
    var item_slot_x = -100;
    var item_slot_y = item_offset;
    var item_w = 8;
    var item_d = item_w + item_offset;

    self.items.children('.ec-dot').each(function() {
      var item = $(this).data('event');
      var m = item._starttime;


      var x = Math.floor(item_offset + ((self.width - (item_offset*2)) / self.timespan) * (m - min_time_ms));

      if (x < -item_w) {
        $(this).css('left', -200);
      } else if (x > self.width + item_w) {
        $(this).css('left', self.width + 200);
      } else {
        var xf = x % item_d;
        x = x - xf;
        var y = item_offset;

        var pushed = false;
        var xoffs = item_slot_x;
        if ((x + xf - item_slot_x) <= item_w) {
          pushed = true;
          x = xoffs;
          y = item_slot_y + item_d;
          if (y > self.items_h - item_offset) {
            xoffs += item_d;
            x = xoffs;
            y = item_offset;
          }
        } else {
          item_slot_y = item_offset;
        }

        if (!pushed) {
          x += xf;
        }

        item_slot_x = x;
        item_slot_y = y;

        $(this).css('left', x).css('top', y);
      }
    });
  };

  $.fn.EventControl = function(options) {
    return this.each(function() {
      var element = $(this);
      var self = element.data('eventcontrol');
      if (!self) {
        element.data('eventcontrol', new EventControl(element, options));
      } else if (options === undefined) {
        return self.save_state();
      } else {
        self.load_state(options);
      }
    });
  };

}(jQuery));

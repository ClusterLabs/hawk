// Copyright (c) 2016 Kristoffer Gronlund <kgronlund@suse.com>
// See COPYING for license.

(function($) {
  function unit_in_timespan(h, min_time, timespan) {
    var day = 24*3600*1000;
    var year = 365*day;
    if (h > day) {
      if (timespan > year*4) {
        var s = moment(min_time).startOf('year');
        var e = min_time + timespan;
        var r = [s];
        var yy = s.year();
        while (s < e) {
          yy += 1;
          s = moment(yy + "-01-01", 'YYYY-MM-DD');
          r.push(s);
        }
        if (r.length > 20) {
          r = r.slice(0, 20);
        }
        return r;
      }
    }
    var s = min_time - (min_time % h);
    var e = min_time + timespan;
    if (h > 15*60*1000) {
      s -= 3600*1000;
    }
    var r = [s];
    while (s < e) {
      s += h;
      if (s >= min_time && s <= e) {
        r.push(s);
      }
    }
    if (r.length > 20) {
      r = r.slice(0, 20);
    }
    return r;
  }

  var MIN_SPAN = 10000;
  var MAX_SPAN = 1000 * 3600 * 24 * 365 * 100;
  var MAJSPANS = [4*365*24*3600*1000, 365*24*3600*1000, 120*24*3600*1000, 42*24*3600*1000, 28*24*3600*1000, 21*24*3600*1000, 14*24*3600*1000, 10*24*3600*1000];
  var MAJUNITS = [  365*24*3600*1000, 120*24*3600*1000,  31*24*3600*1000, 21*24*3600*1000, 14*24*3600*1000, 7*24*3600*1000,   4*24*3600*1000,  2*24*3600*1000];
  var MINSPANS = [3*24*3600*1000, 2*24*3600*1000, 24*3600*1000, 12*3600*1000, 6*3600*1000, 3*3600*1000,  3600*1000, 45*60*1000, 30*60*1000, 20*60*1000, 10*60*1000, 5*60*1000, 3*60*1000, 60*1000, 45*1000, 20*1000, 12*1000, 0];
  var MINUNITS = [  12*3600*1000,    6*3600*1000,  4*3600*1000,  3*3600*1000,   3600*1000,  30*60*1000, 15*60*1000,  5*60*1000,  4*60*1000,  3*60*1000,  2*60*1000,   60*1000,   30*1000, 15*1000, 10*1000,  5*1000,  2*1000, 1000];

  var EventControl = function(element, options) {
    this.settings = $.extend({
      onhover: function(item, element, event, inout) {},
      onclick: function(item, element, event) {},
      oncreate: function(item, element) {},
      data: [],
      hammertime: false,
      items_height: 113,
      markers_height: 31,
      item_width: 14,
      item_offset: 2,
      item_slot_x: -100,
      displayUTC: false
    }, options);

    this.element = element;
    this.width = element.width();

    this.items_h = this.settings.items_height;
    this.markers_h = this.settings.markers_height;
    this.item_width = this.settings.item_width;
    this.item_offset = this.settings.item_offset;
    this.item_slot_x = this.settings.item_slot_x;
    this._dragging = null;
    this._drag_x = 0;

    element.addClass('eventcontrol');
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
    this.pan_min = this.min_time.clone();
    this.pan_max = this.max_time.clone();
    this.timespan = MAX_SPAN;
    this.max_timespan = MAX_SPAN;
    this.center_time = this.min_time.valueOf() + MAX_SPAN * 0.5;
    this.init();
    return this;
  };

  EventControl.prototype.init = function() {
    var self = this;
    var element = this.element;

    function stop_dragging() {
      element.children('.ec-draggable').removeClass('ec-dragging');
      self._dragging = null;
    }

    function pan_with_delta(dragdelta, min_time, max_time) {
      if (dragdelta > 0.9) {
        dragdelta = 0.9;
      } else if (dragdelta < -0.9) {
        dragdelta = -0.9;
      }
      var time_offset = dragdelta * self.timespan;
      var new_min_time = moment(min_time + time_offset);
      var new_max_time = moment(max_time + time_offset);
      // disallow pan if panning to where there are no data points
      if ((new_min_time > self.pan_max && new_min_time > min_time) ||
          (new_max_time < self.pan_min && new_max_time < max_time)) {
        return;
      }
      if (!new_min_time.isSame(self.min_time) || new_max_time.isSame(self.max_time)) {
        self.update_timespan(new_min_time, new_max_time);
      }
    }

    if (self.settings.hammertime) {
      self.mc = new Hammer.Manager(self.element.get()[0]);
      self.mc.add(new Hammer.Pan());
      // Tap recognizer with minimal 2 taps
      self.mc.add( new Hammer.Tap({ event: 'doubletap', taps: 2 }) );
      // Single tap recognizer
      self.mc.add( new Hammer.Tap({ event: 'singletap' }) );
      self.mc.get('doubletap').recognizeWith('singletap');
      // we only want to trigger a tap, when we don't have detected a doubletap
      self.mc.get('singletap').requireFailure('doubletap');

      self.mc.on("panstart panleft panright singletap doubletap tap", function(e) {
        if (e.type == "singletap") {
          var tgt = $(e.target);
          if (tgt.hasClass('ec-dot')) {
            self.settings.onclick.call(self, tgt.data('event'), tgt, e);
          }
        } else if (e.type == "panstart") {
          self._pan_min_time = self.min_time.valueOf();
          self._pan_max_time = self.max_time.valueOf();
        } else if (e.type == "panleft" || e.type == "panright") {
          var deltapx = -e.deltaX;
          var dragdelta = deltapx / self.width;

          pan_with_delta(dragdelta, self._pan_min_time, self._pan_max_time);
        } else if (e.type == "doubletap") {
          var base = element.offset();
          var dir = 1;
          var offset = (e.center.x - base.left) / self.width;
          self.zoom(dir, offset);
        } else {
          console.log("Unexpected hammer event", e.type);
        }
      });

    } else {
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

      $('body').mouseup(function(e) {
        if (e.which == 1) {
          stop_dragging();
        }
      });

      $('body').on("dragend",function(){
        stop_dragging();
      });

      $('body').mousemove(function(e) {
        if (e.which == 1 && self._dragging) {
          var deltapx = -(e.pageX - self._drag_x);
          var dragdelta = deltapx / self.width;
          pan_with_delta(dragdelta, self._drag_min_time, self._drag_max_time);
        }
      });
    }

    $(window).resize(function() {
      if (!self._dirty) {
        if (self.min_time && self.max_time) {
          self._dirty = true;
          window.setTimeout(function() {
            var mit = self.min_time.clone();
            var mat = self.max_time.clone();
            self.update_timespan(mit, mat);
          }, 400);
        }
      }
    });

    element.on('mousewheel', function(event) {
      event.preventDefault();
      var dir = event.deltaY;
      var base = element.offset();
      var offset = (event.pageX - base.left) / self.width;
      self.zoom(dir, offset);
    });

    $.each(self.settings.data, function(i, item) {
      self.items.append('<div class="ec-dot" style="left:0px;top:0px;"></div>');
      var elem = self.items.children('.ec-dot:last-child');
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

    self.min_time.subtract(5, 's');
    self.max_time.add(5, 's');
    self.center_time = self.min_time.valueOf() + (self.max_time.valueOf() - self.min_time.valueOf()) * 0.5;

    self.pan_min = self.min_time.clone();
    self.pan_max = self.max_time.clone();

    self.update_timespan(self.min_time.clone(), self.max_time.clone());
  };

  EventControl.prototype.save_state = function() {
    return {min_time: this.min_time.valueOf(), max_time: this.max_time.valueOf()};
  };

  EventControl.prototype.load_state = function(state) {
    this.update_timespan(state.min_time, state.max_time);
  };

  EventControl.prototype.zoom = function(dir, focus) {
    if (focus === undefined) {
      focus = 0.5;
    }

    var new_min_time = this.min_time.clone();
    var new_max_time = this.max_time.clone();
    var delta;

    if (dir < 0) {
      delta = this.timespan * 0.5;
      new_min_time.subtract(delta * focus, 'ms');
      new_max_time.add(delta * (1.0 - focus), 'ms');
    } else {
      delta = this.timespan * 0.25;
      new_min_time.add(delta * focus, 'ms');
      new_max_time.subtract(delta * (1.0 - focus), 'ms');
    }

    return this.update_timespan(new_min_time, new_max_time);
  };

  EventControl.prototype.update_timespan = function(new_min_time, new_max_time) {
    var self = this;
    var element = this.element;
    var i = 0;

    self._dirty = false;
    self.width = element.width();

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
    var min_unit = null;

    var format_time = self.settings.displayUTC ? function(t, fmt) {
      return moment.utc(t).format(fmt);
    } : function(t, fmt) {
      return moment(t).format(fmt);
    };


    if (self.timespan >= 6*24*3600*1000) {
      min_unit = null;
      if (self.timespan > 4*365*24*3600*1000) {
        major_fmt = 'YYYY';
      } else if (self.timespan > 120*24*3600*1000) {
        major_fmt = 'YYYY-MM';
      }
      for (i = 0; i < MAJSPANS.length; i++) {
        if (self.timespan > MAJSPANS[i]) {
          maj_unit = MAJUNITS[i];
          break;
        }
      }
    } else {
      for (i = 0; i < MINSPANS.length; i++) {
        if (self.timespan > MINSPANS[i]) {
          min_unit = MINUNITS[i];
          break;
        }
      }
      if (min_unit < 60*1000) {
        minor_fmt = 'HH:mm:ss';
      }
    }

    major = unit_in_timespan(maj_unit, min_time_ms, self.timespan);

    var lastlblend = -1;
    var existing_ticks = self.ticks.children('.ec-tick');
    var existing_labels = self.labels.children('.ec-label,.ec-region-label');
    var tick_idx = 0;
    var label_idx = 0;

    function addlabel(cls, l, t, lbl) {
      if (l > lastlblend) {
        if (label_idx < existing_labels.length) {
          var label = $(existing_labels[label_idx]);
          label.css('left', l).css('top', t).text(lbl).addClass(cls).removeClass((cls == 'ec-label') ? 'ec-region-label' : 'ec-label');
          lastlblend = l + label.width();
          label_idx += 1;
        } else {
          self.labels.append(['<div class="', cls, '" style="left:', l, 'px;top:', t, 'px;">', lbl, '</div>'].join(""));
          lastlblend = l + self.labels.children('.' + cls + ':last-child').width();
        }
      }
    }

    function addtick(l, t, h) {
      if (tick_idx < existing_ticks.length) {
        var tick = $(existing_ticks[tick_idx]);
        tick.css('left', l).css('top', t).css('height', h);
        tick_idx += 1;
      } else {
        self.ticks.append(['<div class="ec-tick" style="left:', l, 'px;top:', t, 'px;height:', h, 'px;"></div>'].join(''));
      }
    }

    var span = self.width / self.timespan;
    var ts;
    var xoffs;

    if (min_unit !== null) {
      minor = unit_in_timespan(min_unit, min_time_ms, self.timespan);

      for (i = 0; i < minor.length; i++) {
        ts = minor[i];
        xoffs = span * (ts - min_time_ms);
        addtick(xoffs, 1, self.items_h + 1 + self.markers_h);
        addlabel('ec-label', xoffs + 1, self.items_h + 1, format_time(ts, minor_fmt));
      }
    } else {
      for (i = 0; i < major.length; i++) {
        addtick(span * (major[i] - min_time_ms), 1, self.items_h * 0.5);
      }
    }

    lastlblend = -1;
    for (i = 0; i < major.length; i++) {
      ts = major[i];
      var l = span * (ts - min_time_ms);
      if (l < 2) {
        if (i + 1 < major.length) {
          var next = span * (major[i + 1] - min_time_ms);
          if (next > 60) {
            l = 2;
          }
        } else {
          l = 2;
        }
      }
      addlabel('ec-region-label', l + 1, self.items_h + self.markers_h - 14, format_time(ts, major_fmt));
    }

    for (i = tick_idx; i < existing_ticks.length; i++) {
      $(existing_ticks[i]).remove();
    }
    for (i = label_idx; i < existing_labels.length; i++) {
      $(existing_labels[i]).remove();
    }

    var item_offset = self.item_offset;
    var item_slot_x = self.item_slot_x;
    var item_slot_y = item_offset;
    var item_w = self.item_width;
    var item_d = item_w + item_offset;
    var items = self.items.children('.ec-dot');

    span = (self.width - (item_offset * 2)) / self.timespan;

    var push_rows = 0;

    for (i = 0; i < items.length; i++) {
      var elem = $(items[i]);
      var item = elem.data('event');
      var m = item._starttime;

      if ((span * (m - min_time_ms)) < -(item_w + item_offset) * 6) {
        elem.css('display', 'none');
        continue;
      } else {
        elem.css('display', '');
      }

      var x = Math.floor(item_offset + span * (m - min_time_ms));
      var xf = x % item_d;
      x = x - xf;
      var y = item_offset;
      var pushed = false;
      xoffs = item_slot_x;
      if ((x + xf - item_slot_x) <= item_w) {
        pushed = true;
        x = xoffs;
        y = item_slot_y + item_d;
        if (y > self.items_h - item_offset) {
          xoffs += item_d;
          x = xoffs;
          y = item_offset;
          push_rows += 1;
        }
      } else {
        item_slot_y = item_offset;
        push_rows = 0;
      }

      if (!pushed) {
        x += xf;
      } else if (push_rows > 5) {
        elem.css('display', 'none');
        continue;
      }

      item_slot_x = x;
      item_slot_y = y;

      elem.css('left', x).css('top', y);
    }
  };

  $.fn.EventControl = function(options) {
    var command_args = Array.prototype.slice(arguments, 1);
    return this.each(function() {
      var element = $(this);
      var self = element.data('eventcontrol');
      if (!self) {
        self = new EventControl(element, options);
        element.data('eventcontrol', self);
      } else if (options === undefined) {
        return self.save_state();
      } else if (options == 'zoom-in') {
        return self.zoom.apply(self, [1].concat(command_args));
      } else if (options == 'zoom-out') {
        return self.zoom.apply(self, [-1].concat(command_args));
      } else {
        self.load_state(options);
      }
      return self;
    });
  };
}(jQuery));

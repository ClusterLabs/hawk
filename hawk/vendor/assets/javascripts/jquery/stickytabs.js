/**
 * jQuery Plugin: Sticky Tabs
 * License: Public Domain
 * https://github.com/timabell/jquery.stickytabs/
 *
 * Usage:
 *   $('.nav-tabs').stickyTabs();
 */

(function ( $ ) {
    $.fn.stickyTabs = function() {
        context = this

        // Show the tab corresponding with the hash in the URL, or the first tab.
        var showTabFromHash = function() {
          var hash = window.location.hash;
          var selector = hash ? 'a[href="' + hash + '"]' : 'li.active > a';
          $(selector, context).tab('show');
        }

        // Set the correct tab when the page loads
        showTabFromHash(context)

        // Set the correct tab when a user uses their back/forward button
        window.addEventListener('hashchange', showTabFromHash, false);

        // Change the URL when tabs are clicked
        $('a', context).on('click', function(e) {
          history.pushState(null, null, this.href);
        });

        return this;
    };
}( jQuery ));

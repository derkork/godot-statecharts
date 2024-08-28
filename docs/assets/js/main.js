---
exclude_in_search: true
layout: null
---
(function($) {
    'use strict';
    $(function() {
        $('[data-toggle="tooltip"]').tooltip();
        $('[data-toggle="popover"]').popover();
        $('.popover-dismiss').popover({
            trigger: 'focus'
        })
    });

    function bottomPos(element) {
        return element.offset().top + element.outerHeight();
    }
    $(function() {
        var promo = $(".js-td-cover");
        if (!promo.length) {
            return
        }
        var promoOffset = bottomPos(promo);
        var navbarOffset = $('.js-navbar-scroll').offset().top;
        var threshold = Math.ceil($('.js-navbar-scroll').outerHeight());
        if ((promoOffset - navbarOffset) < threshold) {
            $('.js-navbar-scroll').addClass('navbar-bg-onscroll');
        }
        $(window).on('scroll', function() {
            var navtop = $('.js-navbar-scroll').offset().top - $(window).scrollTop();
            var promoOffset = bottomPos($('.js-td-cover'));
            var navbarOffset = $('.js-navbar-scroll').offset().top;
            if ((promoOffset - navbarOffset) < threshold) {
                $('.js-navbar-scroll').addClass('navbar-bg-onscroll');
            } else {
                $('.js-navbar-scroll').removeClass('navbar-bg-onscroll');
                $('.js-navbar-scroll').addClass('navbar-bg-onscroll--fade');
            }
        });
    });
}(jQuery));
(function($) {
    'use strict';
    var Search = {
        init: function() {
            $(document).ready(function() {
                $(document).on('keypress', '.td-search-input', function(e) {
                    if (e.keyCode !== 13) {
                        return
                    }
                    var query = $(this).val();
                    var searchPage = "{{ site.url }}{{ site.baseurl }}/search/?q=" + query;
                    document.location = searchPage;
                    return false;
                });
            });
        },
    };
    Search.init();
}(jQuery));

function scrollToAnchor() {
    
    try {
        const offset = window.innerWidth > 768 ? 70 : 0;
        const hash = location.hash ? decodeURIComponent(location.hash) : '';
        if(hash && $(hash).length){
            scrollTo(0, $(hash).offset().top - offset);
        }
    } catch (error) {
        console.log('Anchor not found:', location.hash);
    }
}

function addLinksToAnchors() {
    const anchors = $('h2[id], h3[id], h4[id], h5[id]');
    
    if (anchors.length) {
        anchors.each(function(e) {
            const element = $(anchors[e]);
            const targetUrl = window.location.origin + window.location.pathname + '#' + element.attr('id');
            element.html(element.text() + '<a class="heading-anchor" href="' + targetUrl + '">🔗</a>')
        });
    }
}

$(window).bind('hashchange', function(e){
    scrollToAnchor();
});

$(document).ready(function(){
    scrollToAnchor();
    addLinksToAnchors();
});
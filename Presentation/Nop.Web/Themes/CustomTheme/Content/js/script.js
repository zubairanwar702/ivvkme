// some scripts

function MenuCatLinks() {
    $(".mainNav-other .nav-link, .mainNav .nav-link").on("click", function () {
        var CatLink = $(this).attr("href");
        window.location.href = CatLink;
    });
}
function MenuCatLinksMobile() {
    $(".mainNav-other .first-level .nav-link, .mainNav .first-level .nav-link").on("click", function () {
        var CatLinkMobile = $(this).attr("href");
        window.location.href = CatLinkMobile;
    });
}

function mobileMenu() {
    $("#mainNav_container").prependTo("#off-canvas-left-push");
    $(".header-main .header-links").insertAfter(".header-main .navbar-brand");
    $("#small-search-box-form").insertBefore("#mainNav_container");
}

function leftSideMobile() {
    $(".leftSide").prependTo("#leftSide");
}

function menuCategory() {
    $(".menu-category .dropdown").mouseenter(function () {
        var posY = $(this).offset().top;
        $('.dropdown-menu', this).addClass('show');
    });
    $(".menu-category .dropdown").mouseleave(function () {
        $('.dropdown-menu', this).removeClass('show');
    });
}

function BackToTop() {
    if ($('#back-to-top').length) {
        var scrollTrigger = 100, // px
            backToTop = function () {
                var scrollTop = $(window).scrollTop();
                if (scrollTop > scrollTrigger) {
                    $('#back-to-top').addClass('show');
                } else {
                    $('#back-to-top').removeClass('show');
                }
            };
        backToTop();
        $(window).on('scroll', function () {
            backToTop();
        });
        $('#back-to-top').on('click', function (e) {
            e.preventDefault();
            $('html,body').animate({
                scrollTop: 0
            }, 1000);
        });
    }
}

// jquery ready start
$(document).ready(function() {
	// jQuery code

  $(function () {
    $(document).bind("beforecreate.offcanvas", function (e) {
      var dataOffcanvas = $(e.target).data('offcanvas-component');
    });
    $(document).bind("create.offcanvas", function (e) {
      var dataOffcanvas = $(e.target).data('offcanvas-component');
      //console.log(dataOffcanvas);
      dataOffcanvas.onOpen = function () {
        //console.log('Callback onOpen');
      };
      dataOffcanvas.onClose = function () {
        //console.log('Callback onClose');
      };

    });
    $(document).bind("clicked.offcanvas-trigger clicked.offcanvas", function (e) {
      var dataBtnText = $(e.target).text();
      //console.log(e.type + '.' + e.namespace + ': ' + dataBtnText);
    });
    $(document).bind("open.offcanvas", function (e) {
      var dataOffcanvasID = $(e.target).attr('id');
      //console.log(e.type + ': #' + dataOffcanvasID);
    });
    $(document).bind("resizing.offcanvas", function (e) {
      var dataOffcanvasID = $(e.target).attr('id');
      //console.log(e.type + ': #' + dataOffcanvasID);
    });
    $(document).bind("close.offcanvas", function (e) {
      var dataOffcanvasID = $(e.target).attr('id');
      //console.log(e.type + ': #' + dataOffcanvasID);
    });
    $(document).trigger("enhance");
    });

    $(function () {
        var header = $(".section-header");
        $(window).scroll(function () {
            var scroll = $(window).scrollTop();

            if (scroll >= 150) {
                header.removeClass('noscroll').addClass("scroll");
            } else {
                header.removeClass("scroll").addClass('noscroll');
            }
        });
    });


  if ($(window).width() > 991) {
        menuCategory();
        MenuCatLinks();
  } else {
        mobileMenu();
        MenuCatLinksMobile();
        leftSideMobile();
  }

    BackToTop();
    
    /* ///////////////////////////////////////

    THESE FOLLOWING SCRIPTS ONLY FOR BASIC USAGE, 
    For sliders, interactions and other

    */ ///////////////////////////////////////
    

	//////////////////////// Prevent closing from click inside dropdown
    $(document).on('click', '.dropdown-menu', function (e) {
      e.stopPropagation();
    });

	//////////////////////// Bootstrap tooltip
	if($('[data-toggle="tooltip"]').length>0) {  // check if element exists
		$('[data-toggle="tooltip"]').tooltip()
	} // end if

}); 
// jquery end


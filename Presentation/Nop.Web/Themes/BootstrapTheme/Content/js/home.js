var HomeProducts = new Swiper('.HomeProducts', {
    speed: 400,
    slidesPerView: 1,
    slidesPerColumn: 3,
    spaceBetween: 15,
    navigation: {
      nextEl: '.HomeProducts-nav .custom-button-next',
      prevEl: '.HomeProducts-nav .custom-button-prev'
    },
    breakpoints: {
      0: {
        slidesPerView: 1,
        slidesPerColumn: 3
      },
      767: {
        slidesPerView: 1,
        slidesPerColumn: 3
      },
      992: {
        slidesPerView: 2,
        slidesPerColumn: 1
      },
      1199: {
        slidesPerView: 3,
        slidesPerColumn: 1
      }
    }
});

function getSubList(categoryId) {
    'use strict'
    $.ajax({

        type: "Post",
        url: "/AjaxWidgets/ChildCategory/" + categoryId,
        data: {
            id: categoryId,
        },
        success: function (data) {
            var tab = [];
            for (var i = 0, l = data.length; i < l; i++) {
                tab.push("<li><a href=\"" + data[i].SeName + "\">" + data[i].Name + "</a></li>")
            }

            tab = tab.join("");

            $("#" + categoryId + "-Kat .subListSubCategory").html(tab);
            //$("#" + categoryId + "-Kat .subListSubCatRWD").html(tab);
        }
    });
};
function getCategoryContent(categoryIdSelector) {

    $.ajax({
        type: "Post",
        url: "/AjaxWidgets/FeaturedProductByCategoryId/" + categoryIdSelector,
        data: {
            id: categoryIdSelector,
        },
        success: function (data) {
            var categoryObj = "",
                itemName,
                imgUrl,
                good = [],
                tempPacage = "",
                singleItem = "",
                insertString = "",
                itemsCount = data.length,
                good = [],
                subCatList = [],
                itemTpl = $('script[type="text/template"].sliders').text().split(/\$\{(.+?)\}/g);

            for (var i = 0; i < itemsCount; i++) {
                var probs = data[i];

                // generator for btns
                function btnGeneration() {
                    'use strict';
                    var priceOk = data[i].ProductPrice.PriceValue;

                    var cartBtnAction = "onclick=\"AjaxCart.addproducttocart_catalog('/addproducttocart/catalog/" +
                        data[i].Id + "/1/1'); return false;\"",

                        compareBtnAction = "onclick=\"AjaxCart.addproducttocomparelist('/compareproducts/add/" + data[i].Id + "'); return false;\"",

                        wishBtnAction = "onclick=\"AjaxCart.addproducttocart_catalog('/addproducttocart/catalog/" +
                            data[i].Id + "/2/1'); return false;\"";

                    return {

                        'cartAddBtnAction': cartBtnAction,
                        'compareAddText': compareBtnAction,
                        'wishAddText': wishBtnAction,
                        'itId': probs.Id

                    };
                }
                // reduce number of letters
                function nameLetterReducer() {
                    'use strict';

                    return {
                        'shortName': data[i].Name
                    }
                };

                // prepare declaration of extention
                var btnGenerator = btnGeneration(),
                    nameReduced = nameLetterReducer(),
                    imgSettings = data[i].DefaultPictureModel,
                    priceSettings = data[i].ProductPrice,
                    overviewMode = data[i].ReviewOverviewModel;

                // extend object of probs -> flatObject
                if (nameReduced) {
                    $.extend(probs, nameReduced);
                };
                if (btnGenerator) {
                    $.extend(probs, btnGenerator);
                };
                if (imgSettings) {
                    $.extend(probs, imgSettings);
                };
                if (priceSettings) {
                    $.extend(probs, priceSettings);
                };
                if (overviewMode) {
                    $.extend(probs, overviewMode);
                };

                // prepare item

                singleItem = itemTpl.map(function (tok, i) {
                    return (i % 2) ? probs[tok] : tok;
                }).join('');

                singleItem = singleItem.split("###")[1];
                tempPacage += singleItem;

                // cumulate or or push
                if ((i + 1) % 1 == 0) {
                    var insertString = "<div class=\"swiper-slide\">" + tempPacage + "</div>";
                    good.push(insertString);
                    tempPacage = "";
                } else {
                    insertString = "ok";
                }
            };
            // synchronic of owl carusel -> result join -> implement into html -> hook owl
            $.when(
                $("#" + categoryIdSelector + "-Kat .swiper-container .swiper-wrapper").html(good.join(""))
            ).done(function () {
                var swiperIdselector = $(categoryIdSelector);
                var swiperIdselector = new Swiper("#" + categoryIdSelector + "-slider", {
                    speed: 600,
                    spaceBetween: 15,
                    slidesPerView: 4,
                    breakpoints: {
                        767: {
                            slidesPerView: 2
                        },
                        992: {
                            slidesPerView: 2
                        },
                        1199: {
                            slidesPerView: 3
                        },
                        1250: {
                            slidesPerView: 3
                        }
                    },
                    navigation: {
                        nextEl: $("#" + categoryIdSelector + "-Kat .swiper-container").parent().find('.custom-next'),
                        prevEl: $("#" + categoryIdSelector + "-Kat .swiper-container").parent().find('.custom-prev')
                    }
                });
                $(".CatFeaturedProd .card-product .rating-container").each(function () {
                    var Rsum = $(this).data("ratsum"),
                        Rtot = $(this).data("allrev"),
                        Iid = $(this).data("id"),
                        ratingProcent = ((Rsum * 100) / Rtot) / 5;
                    $(this).find('.rating').css('width', ratingProcent + '%');
                });
            });
        }
    });
}
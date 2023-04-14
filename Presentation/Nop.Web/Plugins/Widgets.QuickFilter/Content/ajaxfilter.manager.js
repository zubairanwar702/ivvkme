$.fn.serializeObject = function () {
    var o = {};
    var a = this.serializeArray();
    $.each(a, function () {
        if (o[this.name] !== undefined) {
            if (!o[this.name].push) {
                o[this.name] = [o[this.name]];
            }
            o[this.name].push(this.value || '');
        } else {
            o[this.name] = this.value || '';
        }
    });
    return o;
};

var AjaxFilter = {
    url: false,
    spinnerTemplate: "<div class=\"spinner products\"><div class=\"lds-ring\"><div></div><div></div><div></div><div></div></div></div>",
    spinnerToggle: function (wantShow) {
        if (wantShow) {
            $(".ajax-products").html(this.spinnerTemplate);
            $(".ajax-products .spinner.products").show();
        } else {
            $(".ajax-products .spinner.products").hide();
        }
    },
    init: function (url) {
        this.url = url;
    },
    setFilter: function (flt) {
        if (flt.length > 0)

            $("#PageNumber").val(0);
        AjaxFilter.spinnerToggle(true)

        $.ajax({
            cache: false,
            url: this.url,
            data: { model: $('#ajaxfilter-form').serializeObject(), typ: flt },
            type: 'post',
            success: this.reloadFilters,
        });
    },
    reloadPages: function () {
        var pager = $('.pager');

        if (void 0 != pager && pager.length > 0) {
            $("a", pager).each(function () {
                $(this).click(function (e) {
                    e.preventDefault();

                    var hrefAttr = $(this).attr("href");
                    hrefAttr = hrefAttr.split("pagenumber=")[1];

                    if (hrefAttr == undefined) {
                        hrefAttr = 1;
                    };
                    var pageNumber = hrefAttr - 1;
                    $("#PageNumber").val(pageNumber);
                    AjaxFilter.setFilter('');
                });
            });
        }
    },
    reloadFilters: function (response) {

        AjaxFilter.spinnerToggle(false);

        if (response.Data) {


            $('body,html').animate({ scrollTop: $('.ajax-products').position().top }, 'fast');
            if (response.Products != null) {
                $('.ajax-products').html(response.Products);
                AjaxFilter.reloadPages();
            }
            if (response.Url.length > 0) {
                history.pushState(null, null, response.Url);
            }
            if (response.Type.length > 0) {
                if (response.Type != 'm') {

                    $(".manufacturer-section input:checkbox").attr("disabled", true);
                    $('#manufacturers-filter-section .ajaxfilter-section ul li label span').each(function (entry) {
                        $(this).text('(0)');
                    });

                    $(".manufacturer-section select option").not("option:selected").not("option:first-of-type").attr('disabled', 'disabled')

                    if (response.Data.manufacturerModel.Manufacturers.length > 0) {
                        response.Data.manufacturerModel.Manufacturers.forEach(function (entry) {
                            $(".manufacturer-section").find("input[value=" + entry.Id + "]").attr("disabled", false);
                            $('#manufacturers-filter-section .ajaxfilter-section ul li[data-id=' + entry.Id + '] label span').text('(' + entry.Count + ')');
                            $(".manufacturer-section select option[value='" + entry.Id + "']").attr('disabled', false);
                        });
                    }

                }
                if (response.Type.startsWith('s')) {
                    var id = response.Type.split('-').pop();
                    var specSection = $('.specification-section .filter-section');
                    specSection.each(function (entry) {
                        var specification = $(this);

                        var idSpec = $(this).attr("data-id");
                        if (idSpec != id) {
                            $(this).find("input:checkbox").attr("disabled", true);
                            $(this).find("select option").not("option:selected").not("option:first-of-type").attr('disabled', 'disabled');

                            $('#specification-filter-section .specification-section .filter-section[data-id=' + idSpec + ']  .ajaxfilter-section ul li label span').each(function (entry) {
                                $(this).text('(0)');
                            });
                            if (response.Data.specyficationModel.SpecificationAttributes.length > 0) {
                                response.Data.specyficationModel.SpecificationAttributes.filter(function (item) {
                                    item.SpecificationAttributeOptions.filter(function (option) {
                                        $('#specification-filter-section .specification-section .filter-section[data-id=' + item.Id + '] .ajaxfilter-section ul li[data-id=' + option.Id + '] label span').text('(' + option.Count + ')');
                                    });
                                });
                            }

                        }
                        response.Data.specyficationModel.SpecificationAttributes.filter(function (item) {
                            if (item.Id == idSpec) {
                                item.SpecificationAttributeOptions.forEach(function (option) {
                                    specification.find("input[value=" + option.Id + "]").attr("disabled", false);
                                    specification.find("select option[value='" + option.Id + "']").attr('disabled', false);
                                });
                            }
                        });
                        specification.find('input[type=checkbox]:disabled:checked').attr('disabled', false);
                    });


                }
                else {
                    var specSection = $('.specification-section .filter-section');
                    specSection.each(function (entry) {
                        var specification = $(this);
                        $(this).find("input:checkbox").attr("disabled", true);
                        $(this).find("select option").not("option:selected").not("option:first-of-type").attr('disabled', 'disabled')
                        var idSpec = $(this).attr("data-id");
                        response.Data.specyficationModel.SpecificationAttributes.filter(function (item) {
                            if (item.Id == idSpec) {
                                item.SpecificationAttributeOptions.forEach(function (option) {
                                    specification.find("input[value=" + option.Id + "]").attr("disabled", false);
                                    specification.find("select option[value='" + option.Id + "']").attr('disabled', false);
                                });
                            }
                        });
                        specification.find('input[type=checkbox]:disabled:checked').attr('disabled', false);

                    });

                    $('#specification-filter-section .specification-section .filter-section .ajaxfilter-section ul li label span').each(function (entry) {
                        $(this).text('(0)');
                    });
                    if (response.Data.specyficationModel.SpecificationAttributes.length > 0) {
                        response.Data.specyficationModel.SpecificationAttributes.filter(function (item) {
                            item.SpecificationAttributeOptions.filter(function (option) {
                                $('#specification-filter-section .specification-section .filter-section[data-id=' + item.Id + '] .ajaxfilter-section ul li[data-id*=' + option.Id + '] label span').text('(' + option.Count + ')')
                            });
                        });
                    }
                }
                if (response.Type.startsWith('a')) {
                    var id = response.Type.split('-').pop();
                    var attrSection = $('#attribute-filter-section .filter-section').not("." + response.Type + "");
                    attrSection.each(function (entry) {
                        var attribute = $(this);
                        $(this).find("input:checkbox").attr("disabled", true);
                        $(this).find("select option").not("option:selected").not("option:first-of-type").attr('disabled', 'disabled');

                        var idattr = $(this).attr("data-id");
                        $('#attribute-filter-section .filter-section[data-id=' + idattr + '] .ajaxfilter-section ul li label span').each(function (entry) {
                            $(this).text('(0)');
                        });

                        response.Data.attributesModel.ProductVariantAttributes.filter(function (item) {
                            if (item.Id == idattr) {
                                item.ProductVariantAttributesOptions.forEach(function (option) {
                                    attribute.find("input[value='" + option.Name + "']").attr("disabled", false);
                                    attribute.find("select option[value='" + option.Name + "']").attr('disabled', false);
                                    $('#attribute-filter-section .filter-section[data-id=' + item.Id + '] .ajaxfilter-section ul li[data-id="' + option.Name + '"] label span').text('(' + option.Count + ')')
                                });
                            }
                            else {
                                item.ProductVariantAttributesOptions.forEach(function (option) {
                                    $('#attribute-filter-section .filter-section[data-id=' + item.Id + '] .ajaxfilter-section ul li[data-id="' + option.Name + '"] label span').text('(' + option.Count + ')')
                                });
                            }
                        });
                        attrSection.find('input[type=checkbox]:disabled:checked').attr('disabled', false);
                    });



                }
                else {
                    var attrSection = $('#attribute-filter-section .filter-section');
                    attrSection.each(function (entry) {
                        var attribute = $(this);
                        $(this).find("input:checkbox").attr("disabled", true);
                        $(this).find("select option").not("option:selected").not("option:first-of-type").attr('disabled', 'disabled');

                        var idattr = $(this).attr("data-id");
                        response.Data.attributesModel.ProductVariantAttributes.filter(function (item) {
                            if (item.Id == idattr) {
                                item.ProductVariantAttributesOptions.forEach(function (option) {
                                    attribute.find("input[value='" + option.Name + "']").attr("disabled", false);
                                    attribute.find("select option[value='" + option.Name + "']").attr('disabled', false);
                                });
                            }
                        });
                        attrSection.find('input[type=checkbox]:disabled:checked').attr('disabled', false);
                    });

                    $('#attribute-filter-section .filter-section .ajaxfilter-section ul li label span').each(function (entry) {
                        $(this).text('(0)');
                    });

                    if (response.Data.attributesModel.ProductVariantAttributes.length > 0) {
                        response.Data.attributesModel.ProductVariantAttributes.filter(function (item) {
                            item.ProductVariantAttributesOptions.filter(function (option) {
                                $('#attribute-filter-section .filter-section[data-id*=' + item.Id + '] .ajaxfilter-section ul li[data-id="' + option.Name + '"] label span').text('(' + option.Count + ')')
                            });
                        });
                    }

                }

            }
        }
    }
}

$.urlParam = function (purl, name) {
    var results = new RegExp('[\?&]' + name + '=([^&#]*)').exec(purl);
    if (results == null) {
        return null;
    }
    else {
        return decodeURI(results[1]) || 0;
    }
}


$(document).ready(function () {

    $.each($('#products-orderby option'), function (i, v) {
        var orderby = $.urlParam($(v).val().toLowerCase(), 'orderby');
        $(v).val(orderby);
    });
    $.each($('#products-pagesize option'), function (i, v) {
        var pagesize = $.urlParam($(v).val().toLowerCase(), 'pagesize');
        $(v).val(pagesize);
    });

    if ($('#products-orderby').val() == null) {
        $('#products-orderby').val(2).change();
    }

    $('#products-orderby').prop('onchange', '').unbind('onchange').change(function (e) {
        $("#SortOption").val(this.value);
        AjaxFilter.setFilter('');
    });

    $('#products-pagesize').prop('onchange', '').unbind('onchange').change(function (e) {
        $("#PageSize").val(this.value);
        AjaxFilter.setFilter('');
    });

    $(".viewmode-icon").on("click", function (e) {
        e.preventDefault();
        if ($(this).hasClass("grid")) {
            $('#ViewMode').val('grid');
            $('.product-list').removeClass('product-list').addClass('product-grid');
        } else {
            $('#ViewMode').val('list');
            $('.product-grid').removeClass('product-grid').addClass('product-list');
        }
        AjaxFilter.setFilter('');
    });

    AjaxFilter.reloadPages();

});



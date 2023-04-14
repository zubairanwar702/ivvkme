
var CatalogProducts = new Swiper('.CatalogProducts', {
    speed: 400,
    slidesPerView: 1,
    slidesPerColumn: 3,
    spaceBetween: 15,
    navigation: {
        nextEl: '.CatalogProducts-nav .custom-button-next',
        prevEl: '.CatalogProducts-nav .custom-button-prev'
    }
});
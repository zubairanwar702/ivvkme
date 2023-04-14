using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Xml;
using Nop.Core.Http;
using Nop.Services.Directory;
using Nop.Services.Localization;
using Nop.Services.Logging;
using Nop.Services.Plugins;

namespace Nop.Plugin.ExchangeRate.EcbExchange
{
    public class FloatRatesExchangeRateProvider : BasePlugin, IExchangeRateProvider
    {
        #region Fields

        private readonly IHttpClientFactory _httpClientFactory;
        private readonly ILocalizationService _localizationService;
        private readonly ILogger _logger;

        #endregion

        #region Ctor

        public FloatRatesExchangeRateProvider(IHttpClientFactory httpClientFactory,
            ILocalizationService localizationService,
            ILogger logger)
        {
            _httpClientFactory = httpClientFactory;
            _localizationService = localizationService;
            _logger = logger;
        }

        #endregion

        #region Methods

        /// <summary>
        /// Gets currency live rates
        /// </summary>
        /// <param name="exchangeRateCurrencyCode">Exchange rate currency code</param>
        /// <returns>Exchange rates</returns>
        public IList<Core.Domain.Directory.ExchangeRate> GetCurrencyLiveRates(string exchangeRateCurrencyCode)
        {
            if (exchangeRateCurrencyCode == null)
                throw new ArgumentNullException(nameof(exchangeRateCurrencyCode));

            //add exchange currency with rate 1
            var ratesToExchangeCurrency = new List<Core.Domain.Directory.ExchangeRate>
            {
                new Core.Domain.Directory.ExchangeRate
                {
                    CurrencyCode = exchangeRateCurrencyCode,
                    Rate = 1,
                    UpdatedOn = DateTime.UtcNow
                }
            };

            //get exchange rates to exchange currency from floatrates.com
            try
            {
                var httpClient = _httpClientFactory.CreateClient(NopHttpDefaults.DefaultHttpClient);
                var stream = httpClient.GetStreamAsync($"http://www.floatrates.com/daily/{exchangeRateCurrencyCode}.xml").Result;

                //load XML document
                var document = new XmlDocument();
                document.Load(stream);

                //get daily rates
                var dailyRates = document.SelectNodes("channel/item");
                var updateDate = DateTime.UtcNow;

                foreach (XmlNode currency in dailyRates)
                {
                    //get rate
                    if (!decimal.TryParse(currency.SelectSingleNode("exchangeRate").InnerText, out var currencyRate))
                        continue;

                    ratesToExchangeCurrency.Add(new Core.Domain.Directory.ExchangeRate()
                    {
                        CurrencyCode = currency.SelectSingleNode("targetCurrency").InnerText,
                        Rate = currencyRate,
                        UpdatedOn = updateDate
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.Error("FloatRates exchange rate provider", ex);
            }

            return ratesToExchangeCurrency;
        }

        /// <summary>
        /// Install the plugin
        /// </summary>
        public override void Install()
        {
            //locales
            _localizationService.AddOrUpdatePluginLocaleResource("Plugins.ExchangeRate.FloatRatesExchange.Error", "You can use Float Rates exchange rate provider only when the primary exchange rate currency is supported by FlaotRates.com");

            base.Install();
        }

        /// <summary>
        /// Uninstall the plugin
        /// </summary>
        public override void Uninstall()
        {
            //locales
            _localizationService.DeletePluginLocaleResource("Plugins.ExchangeRate.FloatRatesExchange.Error");

            base.Uninstall();
        }

        #endregion

    }
}
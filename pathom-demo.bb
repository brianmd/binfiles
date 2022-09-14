;; doesn't work because one of the api services is usually down
;; bb pathom-demo.bb :ip '"198.29.213.3"'

;; if cannot find a java runtime, do the ln command here:
;;   https://stackoverflow.com/questions/65601196/how-to-brew-install-java

(ns pathom-babashka
  (:require
    [babashka.deps :as deps]))

(deps/add-deps
  '{:deps {borkdude/spartan.spec {:git/url "https://github.com/borkdude/spartan.spec"
                                  :sha     "03e1583622f7f3073e18d05b69f3ab6f2cf012b6"}
           com.wsscode/pathom3   {:mvn/version "2021.07.10-alpha"}}})

(require 'spartan.spec)
(require '[cheshire.core :as json])
(require '[com.wsscode.pathom3.connect.operation :as pco])
(require '[com.wsscode.pathom3.connect.built-in.resolvers :as pbir])
(require '[com.wsscode.pathom3.connect.indexes :as pci])
(require '[com.wsscode.pathom3.connect.operation :as pco])
(require '[com.wsscode.pathom3.interface.eql :as p.eql])

(pco/defresolver geo-from-ip [{:keys [geo-js/ip]}]
  {::pco/output [:geo-js/asn
                 :geo-js/organization_name
                 :geo-js/organization
                 :geo-js/ip
                 :geo-js/timezone
                 :geo-js/longitude
                 :geo-js/latitude
                 :geo-js/country
                 :geo-js/country_code3
                 :geo-js/area_code
                 :geo-js/region
                 :geo-js/city
                 :geo-js/country_code
                 :geo-js/accuracy
                 :geo-js/continent_code]}
  (-> (slurp (str "https://get.geojs.io/v1/ip/geo/" ip ".json"))
    (json/parse-string #(keyword "geo-js" %))))

(pco/defresolver geo-lat-long->meta-search
  [{:geo-js/keys [longitude latitude]}]
  {:meta-weather/search-latt_long (str latitude "," longitude)})

(pco/defresolver meta-weather-latlong-search
  [{:meta-weather/keys [search-latt_long]}]
  {::pco/output [:meta-weather/distance
                 :meta-weather/title
                 :meta-weather/location_type
                 :meta-weather/woeid
                 :meta-weather/latt_long]}
  (-> (slurp (str "https://www.metaweather.com/api/location/search/?lattlong=" search-latt_long))
    (json/parse-string #(keyword "meta-weather" %))
    first))

(pco/defresolver meta-weather-location
  [{:meta-weather/keys [woeid]}]
  {::pco/output
   [:meta-weather/timezone_name
    :meta-weather/sun_set
    :meta-weather/location_type
    :meta-weather/sun_rise
    :meta-weather/latt_long
    {:meta-weather/parent
     [:meta-weather/title
      :meta-weather/location_type
      :meta-weather/woeid
      :meta-weather/latt_long]}
    :meta-weather/title
    :meta-weather/woeid
    {:meta-weather/sources
     [:meta-weather/title
      :meta-weather/slug
      :meta-weather/url
      :meta-weather/crawl_rate]}
    :meta-weather/time
    {:meta-weather/consolidated_weather
     [:meta-weather/visibility
      :meta-weather/weather_state_name
      :meta-weather/humidity
      :meta-weather/applicable_date
      :meta-weather/air_pressure
      :meta-weather/id
      :meta-weather/weather_state_abbr
      :meta-weather/predictability
      :meta-weather/max_temp
      :meta-weather/the_temp
      :meta-weather/created
      :meta-weather/wind_direction
      :meta-weather/wind_speed
      :meta-weather/min_temp
      :meta-weather/wind_direction_compass]}
    :meta-weather/timezone]}
  (-> (slurp (str "https://www.metaweather.com/api/location/" woeid))
    (json/parse-string #(keyword "meta-weather" %))))

(pco/defresolver meta-weather-location-the-temp
  [{:meta-weather/keys [consolidated_weather]}]
  {::pco/output [:meta-weather/the_temp]}
  (if-let [temp (-> consolidated_weather
                  first
                  :meta-weather/the_temp)]
    {:meta-weather/the_temp temp}))

(pco/defresolver its-cold? [{::keys [temperature cold-threshold]}]
  {::cold? (< temperature cold-threshold)})

(def env
  (pci/register
    [geo-from-ip
     geo-lat-long->meta-search
     meta-weather-latlong-search
     meta-weather-location
     meta-weather-location-the-temp
     its-cold?
     (pbir/constantly-resolver ::cold-threshold 20)
     (pbir/alias-resolver ::ip :geo-js/ip)
     (pbir/alias-resolver :meta-weather/the_temp ::temperature)]))

(defn parse-data-args []
  (apply hash-map (map read-string *command-line-args*)))

(defn main [{:keys [ip] :as args}]
  (println (str "Looking up the temperature on IP " ip "..."))
  (let [{::keys [temperature]}
        (p.eql/process env
          {::ip ip}
          [::temperature])]
    (println (str "Temperature for IP " ip " is " temperature "C"))))

(main (parse-data-args))

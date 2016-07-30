namespace :houses do
  desc "Scrapes houses"
  task scrape: [:trulia, :hotpads]

  task trulia: :environment do
    require 'open-uri'

    base = "http://www.trulia.com"
    url = base + "/for_rent/My%20Custom%20Area___%7D%60vEdn%7CfO%7Cfq%40dnn%400_%60~%40qeJghN_sp/date;d_sort/3p_beds/1200-1900_price/SINGLE-FAMILY_HOME_type"

    page = Nokogiri::HTML(open(url))
    houses = page.css(".propertyList .propertyCard .propertyImageLink")

    puts "Scraping Trulia: #{houses.size} houses"

    houses.each_with_index do |link, idx|
      h = Nokogiri::HTML(open(base + link['href']))

      street = h.at_css('[itemprop="streetAddress"]').text.strip
      city   = h.at_css('[itemprop="addressLocality"]').text.strip
      state  = h.at_css('[itemprop="addressRegion"]').text.strip
      zip    = h.at_css('[itemprop="postalCode"]').text.strip

      description = h.at_css('#corepropertydescription').text.strip

      pets = description.downcase.include?('pet')
      pets = description.downcase.include?('no pet') ? false : pets

      things = h.css('.pdpFeatureList ul li')
      sqft = things.select { |t| t.text.downcase.include?('sqft') }.first.try(:text)
      lot  = things.select { |t| t.text.downcase.include?('acre') }.first.try(:text)

      house = House.where(address: "#{street}, #{city}, #{state} #{zip}").first_or_create
      house.update(sqft: sqft,
                   lot: lot,
                   url: base + link['href'],
                   price: h.at_css('[itemprop="price"]').text.strip,
                   description: description,
                   photo: h.at_css('.mapImg')['src'],
                   pets: pets)

      puts "Scraping Trulia: #{idx + 1}/#{houses.size} #{street}, #{city}, #{state} #{zip}"
    end
  end

  task hotpads: :environment do
    require 'open-uri'

    base = "https://hotpads.com"
    url = base + "/node/api/v2/listing/byQuads?components=basic,useritem,quality,model&limit=4&quads=0320021300122,0320021300123,0320021300132,0320021300133,0320021301022,0320021301023,0320021301032,0320021301033,0320021301122,0320021301123,0320021301132,0320021301133,0320021310022,0320021310023,0320021310032,0320021310033,0320021310122,0320021310123,0320021300300,0320021300301,0320021300310,0320021300311,0320021301200,0320021301201,0320021301210,0320021301211,0320021301300,0320021301301,0320021301310,0320021301311,0320021310200,0320021310201,0320021310210,0320021310211,0320021310300,0320021310301,0320021300302,0320021300303,0320021300312,0320021300313,0320021301202,0320021301203,0320021301212,0320021301213,0320021301302,0320021301303,0320021301312,0320021301313,0320021310202,0320021310203,0320021310212,0320021310213,0320021310302,0320021310303,0320021300320,0320021300321,0320021300330,0320021300331,0320021310230,0320021310231,0320021310320,0320021310321,0320021300322,0320021300323,0320021300332,0320021300333,0320021310232,0320021310233,0320021310322,0320021310323,0320021302100,0320021302101,0320021302110,0320021302111,0320021312010,0320021312011,0320021312100,0320021312101,0320021302102,0320021302103,0320021302112,0320021302113,0320021312012,0320021312013,0320021312102,0320021312103,0320021302120,0320021302121,0320021302130,0320021302131,0320021312030,0320021312031,0320021312120,0320021312121,0320021302122,0320021302123,0320021302132,0320021302133,0320021312032,0320021312033,0320021312122,0320021312123,0320021302300,0320021302301,0320021302310,0320021302311,0320021312210,0320021312211,0320021312300,0320021312301,0320021302302,0320021302303,0320021302312,0320021302313,0320021312212,0320021312213,0320021312302,0320021312303,0320021302320,0320021302321,0320021302330,0320021302331,0320021312230,0320021312231,0320021312320,0320021312321,0320021302322,0320021302323,0320021302332,0320021302333,0320021303222,0320021303223,0320021303232,0320021303233,0320021303322,0320021303323,0320021303332,0320021303333,0320021312222,0320021312223,0320021312232,0320021312233,0320021312322,0320021312323,0320021320100,0320021320101,0320021320110,0320021320111,0320021321000,0320021321001,0320021321010,0320021321011,0320021321100,0320021321101,0320021321110,0320021321111,0320021330000,0320021330001,0320021330010,0320021330011,0320021330100,0320021330101,0320021320102,0320021320103,0320021320112,0320021320113,0320021321002,0320021321003,0320021321012,0320021321013,0320021321102,0320021321103,0320021321112,0320021321113,0320021330002,0320021330003,0320021330012,0320021330013,0320021330102,0320021330103&bedrooms=3,4,5,6,7,8plus&bathrooms=0,0.5,1,1.5,2,2.5,3,3.5,4,4.5,5,5.5,6,6.5,7,7.5,8plus&lowPrice=1000&highPrice=2000&listingTypes=rental,room,sublet&propertyTypes=condo,divided,garden,house,large,medium,townhouse&orderBy=activated&minSqft=1600&minPhotos=0&visible=favorite,inquiry,new,note,notified,viewed&includeVaguePricing=false&incomeRestricted=false&apiV2TraceId=4824621184864273176"

    page = JSON.parse open(url).read

    houses = page["data"].reject {|h| h["listingsGroup"].empty? }.select {|h| h["listingsGroup"] }.map {|h| h["listingsGroup"] }.flatten

    puts "Scraping HotPads: #{houses.size} houses"

    houses.each_with_index do |h, idx|
      street = h["address"]["street"]
      city   = h["address"]["city"]
      state  = h["address"]["state"]
      zip    = h["address"]["zip"]

      detail = Nokogiri::HTML(open(base + h['uri']))

      description = detail.css('.HDPDescription').text

      pets = description.downcase.include?('pet')
      pets = description.downcase.include?('no pet') ? false : pets

      house = House.where(address: "#{street}, #{city}, #{state} #{zip}").first_or_create
      house.update(sqft: detail.css('.sqft').text,
                   url: base + h['uri'],
                   price: detail.css('.price').text,
                   description: description,
                   photo: detail.at_css('.photo-gallery')["src"],
                   pets: pets)

      puts "Scraping HotPads: #{idx + 1}/#{houses.size} #{street}, #{city}, #{state} #{zip}"
    end
  end
end

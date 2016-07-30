namespace :houses do
  desc "Scrapes houses"
  task scrape: [:trulia]

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
end

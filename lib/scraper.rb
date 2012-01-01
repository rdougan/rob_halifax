# encoding: utf-8
class Scraper
    def accounts
        []
    end

    # simple method to remove unnessecary charcters from a stupid halifax string and convert it to a float
    def format_number(number)
        if number
            number = number.gsub(/\s+/, '').gsub(',', '').gsub('£', '').gsub('+', '').to_f
        end

        number
    end
end
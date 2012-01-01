class NorthernBankScraper < Scraper
    def accounts
        # check if all ENV variables are set
        raise InvalidLoginError, "No NORTHERN_BANK_USER_ID environment variable set" if !ENV['NORTHERN_BANK_USER_ID']
        raise InvalidLoginError, "No NORTHERN_BANK_PASSCODE environment variable set" if !ENV['NORTHERN_BANK_PASSCODE']

        # the online banking url
        url = "https://m.northernbank.co.uk/XI?WP=XAI&WO=Logon&WA=MBNBLogon&gsSprog=EN&gsBrand=NB"
        
        # give it a mobile user agent so the loading times is much quicker
        user_agent = "Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1A543 Safari/419.3"

        a = Mechanize.new do |agent|
            agent.user_agent = user_agent
        end

        # load the online banking and login using ENV values
        a.get(url) do |page|
            login_form = page.form_with(:id => 'f') do |login|
                login.fields_with(:name => 'gsAftlnr').first.value = ENV['NORTHERN_BANK_USER_ID']
                login.fields_with(:name => 'gsLogon').first.value = ENV['NORTHERN_BANK_PASSCODE']
            end.submit
        end
        
        page = a.current_page

        # click account buttin
        a.click(page.links_with(:id => 'lnkAccountOverV').first)

        page = a.current_page

        accounts = []
        
        page.root.search('.list li').each do |account|
            hash = {
                :name => account.search('a').first.inner_text
            }

            # get information
            figures = []
            figures << {
                :name => "Balance",
                :value => self.format_number(account.inner_text.match(/Balance:.([-+0-9.]*)/)[1])
            }
            figures << {
                :name => "Available",
                :value => self.format_number(account.inner_text.match(/Available:.([-+0-9.]*)/)[1])
            }

            # go to each account
            a.click(account.search('a').first)

            page = a.current_page

            # get information
            hash[:information] = page.root.search('.content h2').inner_text.split('-').last.strip

            # get transactions
            transactions = []
            page.root.search('ul.list li').each do |transaction|
                value = transaction.inner_text.match(/Amount:.([-+0-9.]*)/)[1]

                transactions << {
                    :is_credit => (value.match('-')) ? false : true,
                    :date => Date.strptime(transaction.inner_text.match(/([0-9][0-9].[0-9][0-9].[0-9][0-9][0-9][0-9])/)[1], '%d.%m.%Y'),
                    :name => transaction.search('a').first.text.gsub!(/\s+/, ' '),
                    :value => self.format_number(value)
        #             :balance => self.format_number(transaction.search('em')[1].text)
                }
            end

            hash[:figures] = figures
            hash[:transactions] = transactions

            # go back
            a.back
            page = a.current_page

            accounts << hash
        end

        accounts
    end
end

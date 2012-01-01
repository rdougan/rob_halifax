# encoding: utf-8

class InvalidLoginError < StandardError
end

require 'open-uri'

class HalifaxController < ApplicationController
    def login
        # check if all ENV variables are set
        raise InvalidLoginError, "No HALIFAX_USERNAME environment variable set" if !ENV['HALIFAX_USERNAME']
        raise InvalidLoginError, "No HALIFAX_PASSWORD environment variable set" if !ENV['HALIFAX_PASSWORD']
        raise InvalidLoginError, "No HALIFAX_SECRET environment variable set" if !ENV['HALIFAX_SECRET']

        # the halifax online banking url
        url = "https://www.halifax-online.co.uk/personal/logon/login.jsp"
        
        # give it a mobile user agent so the loading times is much quicker
        user_agent = "Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1A543 Safari/419.3"

        a = Mechanize.new do |agent|
            agent.user_agent = user_agent
        end

        # load the online banking and login using ENV values
        a.get(url) do |page|
            login_form = page.form_with(:name => 'frmLogin') do |login|
                login.fields_with(:name => 'frmLogin:strCustomerLogin_userID').first.value = ENV['HALIFAX_USERNAME']
                login.fields_with(:name => 'frmLogin:strCustomerLogin_pwd').first.value = ENV['HALIFAX_PASSWORD']
            end.submit
        end
        
        # move to the secret question page
        page = a.current_page

        # loop through each label
        labels = page.labels
        values = []
        labels.each {|l|
            values << ENV['HALIFAX_SECRET'][l.text.match(/\d/)[0].to_i - 1, 1]
        }

        secret_form = page.form_with(:name => 'frmEnterMemorableInformation1') do |form|
            form.fields_with(:name => 'frmEnterMemorableInformation1:formMem1').first.value = "&nbsp;#{values[0]}"
            form.fields_with(:name => 'frmEnterMemorableInformation1:formMem2').first.value = "&nbsp;#{values[1]}"
            form.fields_with(:name => 'frmEnterMemorableInformation1:formMem3').first.value = "&nbsp;#{values[2]}"

            form.click_button(form.buttons.first)
        end

        # move to overview page
        page = a.current_page

        accounts = []
        page.root.search('.account a').each do |account|
            hash = {
                :name => account.search('strong').inner_text,
                :information => account.search('span').inner_text
            }

            # go to each account
            a.click(account)

            page = a.current_page

            # get information
            figures = []
            page.root.search('.accountFigures span').each do |figure|
                figure = figure.inner_text.split(': ')
                figures << {
                    "#{figure[0]}" => self.format_number(figure[1])
                }
            end

            # get transactions
            transactions = []
            page.root.search('.statement > p.debit, .statement > p.credit').each do |transaction|
                transactions << {
                    :is_credit => transaction['class'] == 'credit',
                    :date => Date.strptime(transaction.children.first.text, '%d %b %y'),
                    :name => transaction.search('span').first.text,
                    :value => self.format_number(transaction.search('em').first.text),
                    :balance => self.format_number(transaction.search('em')[1].text)
                }
            end

            hash[:figures] = figures
            hash[:transactions] = transactions

            # go back
            a.back
            page = a.current_page

            accounts << hash
        end

        # respond using JSON
        respond_to do |format|
            format.html {
                render :json => {
                    :success => true,
                    :accounts => accounts
                }
            }
        end
    rescue InvalidLoginError => e
        respond_to do |format|
            format.html {
                render :json => {
                    :success => false,
                    :message => "#{e.message}"
                }
            }
        end
    rescue
        respond_to do |format|
            format.html {
                render :json => {
                    :success => false,
                    :message => "Unknown error"
                }
            }
        end
    end

    # simple method to remove unnessecary charcters from a stupid halifax string and convert it to a float
    def format_number(number)
        if number
            number = number.gsub(/\s+/, '').gsub(',', '').gsub('£', '').gsub('+', '').to_f
        end

        number
    end
end

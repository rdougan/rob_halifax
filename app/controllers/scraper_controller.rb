class InvalidLoginError < StandardError
end

class NotAuthorizedError < StandardError
end

require 'open-uri'

class ScraperController < ApplicationController
    def login
        # authenticate
        if !ENV['UUID'] || ENV['UUID'].split(',').index(params[:uuid]) == nil
            raise NotAuthorizedError, "You do not have permission to view this."
        end

        # scrapers
        halifax = HalifaxScraper.new
        northern = NorthernBankScraper.new

        accounts = [].concat halifax.accounts
        accounts = accounts.concat northern.accounts

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
    rescue NotAuthorizedError => e
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
end

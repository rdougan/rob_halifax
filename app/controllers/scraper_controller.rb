# encoding: utf-8
class InvalidLoginError < StandardError
end

require 'open-uri'

class ScraperController < ApplicationController
    def login
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

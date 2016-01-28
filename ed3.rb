require 'watir-webdriver'
require 'pry-byebug'
require 'nokogiri'
require 'json'

class Bank

	attr_accessor :accounts

	def initialize(login, password)
		@login    = login
		@password = password
		goto_accounts
		parse_accounts
		goto_transactions
		get_transactions_list
		disconnect
	end

	def browser
		@browser ||= Watir::Browser.new
	end

	def goto_accounts
		browser.goto('https://wb.micb.md/frontend/auth/userlogin?execution=e1s1')
		browser.text_field(:id => 'USER_PROPERTY_owwb_ws_loginPageLogin').set(@login)
		browser.text_field(:id => 'USER_PROPERTY_owwb_ws_loginPagePassword').set(@password)
		browser.span(:text => 'Autentificare').click
	end

	def parse_accounts
		@accounts = []
		html = Nokogiri::HTML.fragment(browser.div(:class => "owwb-ws-cards-accounts").html)
		html.css("li.owwb_cs_slideListItemActive").each do |row|
			balance_currency = row.css("li:contains('Suma disponibilă') div")[1].text.gsub("  ", "").gsub("\n", "")
			account = {
				name:          row.css("span.contract-number").text,
				balance:       balance_currency[0..-5].gsub(" ", "").to_f,
				currency_code: balance_currency[-3..-1],
				card_name:     row.css("span:contains('********')").last.text,
				transactions:  []
			}
		  accounts << account
		end
	end

	def goto_transactions
		browser.span(:text => 'Istoria tranzacțiilor').click
		browser.span(:text => 'Extras pentru card').click
		browser.spans(:class => 'owwb-cs-object-rbs-content owwb-cs-default-select-bg').first.click
		browser.span(:text => 'Ultimele 3 luni').click
		sleep 3
	end

	def get_transactions_list
		accounts.each do |account|
		  browser.span(:class => 'owwb-cs-default-select-object-text owwb_cs_selectContent').click
		  browser.spans(:class => 'owwb-cs-object-rbs-content owwb-cs-default-select-bg').last.click
			browser.links(:class => "owwb-cs-default-select-item owwb_cs_selectItem").detect { |link| link.text.include?(account[:card_name]) }.click
			sleep 3

			html = Nokogiri::HTML.fragment(browser.ul(:class => "owwb-ws-statement").html)
		  parse_transactions(account, html)
		end
	end

	def parse_transactions(account, html)
		date = ""
	  html.css("li.owwb_ws_statementItem").each do |li|

	  	divs = li.css("div")
			if divs[0].text.match(/\d{2}\.\d{2}\.\d{2}/)
				date = divs[0].text
				transaction_date = date
			else
				transaction_date = date
			end

	    transaction = {
				date:        Date.strptime( transaction_date , "%d.%m.%y").to_s,
				description: li.css("div[class*='wrapper']").text.gsub("\n", "").gsub("  ", ""),
				amount:      li.css("span[class*='amount-value']").first.text.to_f,
				currency:    li.css("span[class*='currency']").first.text
			}														
	    account[:transactions] << transaction
	  end 
	end

	def disconnect
		browser.span(:class => "owwb-cs-object-rbs-content owwb-cs-button-exit-bg").click
		browser.wait(5) 
		browser.close
	end
end

adapter = Bank.new("Chekushkin", "Fi8ok0vaf9a")
binding.pry

1 + 1




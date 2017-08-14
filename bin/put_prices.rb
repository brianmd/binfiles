#!/bin/zsh
source ~/.zshrc
echo
echo "Ensure you are connected to the production database!!!!!"
echo
echo "Loading rails console and executing ..."
cd ~/Documents/git/summit/blue-harvest
source .envrc
bundle exec rails c <<EOF
require 'json'
rows_str = open('/Users/bmd/Dropbox/summit/git/contact_email_total_prices.out', 'r') { |f| f.gets }
rows = JSON.parse rows_str
rows.each do |id, price|
  ce = ContactEmail.find id
  ce.update_attribute :total_price, price if ce
end

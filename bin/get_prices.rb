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
query = 'select ce.id, sum(li.price)
from contact_emails ce
join carts on carts.id=ce.cart_id
join line_items li on carts.id=li.cart_id
group by ce.id
order by ce.id'
json = (ActiveRecord::Base.connection.execute query).to_a.to_json
open('/Users/bmd/Dropbox/summit/git/contact_email_total_prices.out', 'w') { |f| f.puts json }
EOF
cd /Users/bmd/Dropbox/summit/git
git commit -am 'Updated prices.'

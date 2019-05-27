sudo apt install node.js npm -y
git clone https://github.com/etsy/statsd
cd statsd
vi appInsights.js
npm install appinsights-statsd --save
node stats.js appInsights.js

// https://www.npmjs.com/package/tunnel
//
var tunnel = require('tunnel');
const https = require('https');
 
var tunnelingAgent = tunnel.httpsOverHttp({
  proxy: {
    host: 'localhost',
    port: 4444
  }
});
 
var req = https.request({
  host: 'dash.adsrvr.org',
  port: 443,
  agent: tunnelingAgent
});

